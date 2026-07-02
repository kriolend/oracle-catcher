import os
import oci
import time
import random
import logging
import sys

# === Логирование ===
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%H:%M:%S',
    stream=sys.stdout
)
log = logging.getLogger(__name__)

# Чтение конфигурации из переменных окружения
API_KEY = os.environ.get("ORACLE_API_KEY", "")
key_path = "/tmp/oracle_api_key.pem"
with open(key_path, "w") as f:
    f.write(API_KEY.replace("\\n", "\n"))

config = {
    "user": os.environ.get("ORACLE_USER_OCID", "").strip(),
    "key_file": key_path,
    "fingerprint": os.environ.get("ORACLE_FINGERPRINT", "").strip(),
    "tenancy": os.environ.get("ORACLE_TENANCY_OCID", "").strip(),
    "region": os.environ.get("ORACLE_REGION", "").strip()
}

compartment_id = config["tenancy"]

# Парсинг массивов/списков
ad_string = os.environ.get("ORACLE_AVAILABILITY_DOMAINS", "").strip()
availability_domains = [ad.strip() for ad in ad_string.split(",") if ad.strip()]

IMAGE_ID    = os.environ.get("ORACLE_IMAGE_ID", "").strip()
SHAPE       = os.environ.get("ORACLE_SHAPE", "VM.Standard.A1.Flex").strip()
OCPUS       = int(os.environ.get("ORACLE_OCPUS", "4").strip())
MEMORY_GB   = int(os.environ.get("ORACLE_MEMORY_GB", "24").strip())
SUBNET_OCID = os.environ.get("ORACLE_SUBNET_OCID", "").strip()
SSH_KEY     = os.environ.get("ORACLE_SSH_PUBLIC_KEY", "").strip()
DISPLAY_NAME = os.environ.get("ORACLE_INSTANCE_DISPLAY_NAME", "oracle-catcher-instance").strip()

MIN_WAIT = int(os.environ.get("ORACLE_CATCHER_MIN_WAIT", "10"))
MAX_WAIT = int(os.environ.get("ORACLE_CATCHER_MAX_WAIT", "30"))

# Ограничение времени работы скрипта (по умолчанию 4 минуты = 240 сек),
# чтобы GitHub Actions job корректно завершался.
RUN_DURATION = int(os.environ.get("ORACLE_CATCHER_RUN_DURATION", "240"))

retry_strategy = oci.retry.DEFAULT_RETRY_STRATEGY
compute_client = oci.core.ComputeClient(config, retry_strategy=retry_strategy)

def get_current_capacity():
    try:
        instances = compute_client.list_instances(compartment_id).data
        used_ocpu = 0
        used_mem = 0
        for inst in instances:
            if inst.lifecycle_state not in ["TERMINATING", "TERMINATED"] and inst.shape == SHAPE:
                used_ocpu += int(inst.shape_config.ocpus)
                used_mem += int(inst.shape_config.memory_in_gbs)
        return used_ocpu, used_mem
    except Exception as e:
        log.error(f"Ошибка получения списка инстансов: {e}")
        return 0, 0

def get_cascade_options(used_ocpu):
    available = 4 - used_ocpu
    if available >= 4:
        return [(4, 24), (2, 12), (1, 6)]
    elif available == 3:
        return [(3, 18), (2, 12)]
    elif available == 2:
        return [(2, 12)]
    else:
        return []

def try_launch_instance(ad: str, ocpus: int, memory_gb: int) -> bool:
    display_name = f"{DISPLAY_NAME}-{ocpus}C-{memory_gb}G"
    log.info(f"Пробуем AD: {ad} | Конфиг: {ocpus} OCPU, {memory_gb} GB RAM")
    try:
        launch_details = oci.core.models.LaunchInstanceDetails(
            display_name=display_name,
            compartment_id=compartment_id,
            availability_domain=ad,
            shape=SHAPE,
            shape_config=oci.core.models.LaunchInstanceShapeConfigDetails(
                ocpus=float(ocpus),
                memory_in_gbs=float(memory_gb)
            ),
            source_details=oci.core.models.InstanceSourceViaImageDetails(
                source_type="image",
                image_id=IMAGE_ID
            ),
            create_vnic_details=oci.core.models.CreateVnicDetails(
                subnet_id=SUBNET_OCID,
                assign_public_ip=True
            ),
            metadata={
                "ssh_authorized_keys": SSH_KEY
            }
        )
        response = compute_client.launch_instance(launch_details)
        log.info(f"✅ УСПЕХ! Инстанс {display_name} создаётся: {response.data.id}")
        return True

    except oci.exceptions.ServiceError as e:
        if e.status == 500 and "Out of host capacity" in str(e.message):
            log.warning(f"❌ Нет мест для {ocpus} OCPU в {ad}")
        elif e.status == 429:
            log.warning("🛑 Rate limit (429)! Спим 1 минуту...")
            time.sleep(60)
        elif e.status == 400:
            log.error(f"⚠️ Ошибка (400): {e.message}")
        else:
            log.error(f"⚠️ Ошибка ({e.status}): {e.message}")
    return False

log.info("🚀 Oracle Catcher (GitHub Actions Edition) запущен.")
attempt = 0
start_time = time.time()

while True:
    elapsed = time.time() - start_time
    if elapsed > RUN_DURATION:
        log.info(f"⌛ Время работы ({RUN_DURATION} сек) вышло. Завершаем работу, чтобы GitHub Actions запустил новый Job.")
        sys.exit(0)

    attempt += 1
    used_ocpu, used_mem = get_current_capacity()
    options = get_cascade_options(used_ocpu)
    
    if not options:
        log.info(f"🎉 Достигнут целевой лимит OCPU. Использовано: {used_ocpu}/4.")
        sys.exit(0)

    log.info(f"--- Попытка #{attempt} | Занято OCPU: {used_ocpu}/4 ---")
    
    ads = availability_domains[:]
    random.shuffle(ads)
    
    caught = False
    for ad in ads:
        for (ocpu, mem) in options:
            if try_launch_instance(ad, ocpu, mem):
                caught = True
                break
        if caught:
            break
            
    if caught:
        log.info("🎉 Пойман инстанс! Завершаем текущий Job, чтобы сохранить минуты.")
        sys.exit(0)

    # Jitter (дрожание) чтобы скрыть паттерн бота
    wait = random.randint(MIN_WAIT, MAX_WAIT) + random.randint(1, 15)
    log.info(f"⏳ Следующая попытка через {wait} сек...")
    time.sleep(wait)
