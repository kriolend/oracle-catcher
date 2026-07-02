import os
import oci
import time
import random
import logging
import sys
import smtplib
from email.mime.text import MIMEText

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
RUN_DURATION = int(os.environ.get("ORACLE_CATCHER_RUN_DURATION", "240"))

# Email настройки
EMAIL_FROM = os.environ.get("EMAIL_FROM", "").strip()
EMAIL_TO = os.environ.get("EMAIL_TO", "").strip()
EMAIL_APP_PASSWORD = os.environ.get("EMAIL_APP_PASSWORD", "").strip()

retry_strategy = oci.retry.DEFAULT_RETRY_STRATEGY
compute_client = oci.core.ComputeClient(config, retry_strategy=retry_strategy)


def send_email(subject: str, body: str):
    """Отправить email через Gmail SMTP."""
    if not EMAIL_FROM or not EMAIL_APP_PASSWORD:
        log.warning("Email не настроен — пропускаем отправку.")
        return
    try:
        msg = MIMEText(body, "plain", "utf-8")
        msg["Subject"] = subject
        msg["From"] = EMAIL_FROM
        msg["To"] = EMAIL_TO
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as smtp:
            smtp.login(EMAIL_FROM, EMAIL_APP_PASSWORD)
            smtp.sendmail(EMAIL_FROM, EMAIL_TO, msg.as_string())
        log.info(f"📧 Email отправлен на {EMAIL_TO}")
    except Exception as e:
        log.error(f"Ошибка отправки email: {e}")


def get_instance_ip(instance_id: str) -> str:
    """Ждём пока инстанс запустится и получаем его публичный IP."""
    try:
        network_client = oci.core.VirtualNetworkClient(config)
        for _ in range(30):  # Максимум 5 минут ожидания
            time.sleep(10)
            vnics = compute_client.list_vnic_attachments(
                compartment_id=compartment_id,
                instance_id=instance_id
            ).data
            if vnics:
                vnic = network_client.get_vnic(vnics[0].vnic_id).data
                if vnic.public_ip:
                    return vnic.public_ip
    except Exception as e:
        log.error(f"Ошибка получения IP: {e}")
    return "IP не определён (проверь Oracle Console)"


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


def try_launch_instance(ad: str, ocpus: int, memory_gb: int):
    """Возвращает instance_id при успехе или None при неудаче.
       Возвращает 'LIMIT_EXCEEDED' если превышен лимит аккаунта."""
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
        return response.data.id

    except oci.exceptions.ServiceError as e:
        if e.status == 500 and "Out of host capacity" in str(e.message):
            log.warning(f"❌ Нет мест для {ocpus} OCPU в {ad}")
        elif e.status == 429:
            log.warning("🛑 Rate limit (429)! Спим 1 минуту...")
            time.sleep(60)
        elif e.status == 400 and "service limits were exceeded" in str(e.message):
            log.error(f"🚫 Лимит аккаунта превышен! Нужно запросить увеличение лимитов в Oracle Console.")
            return "LIMIT_EXCEEDED"
        elif e.status == 400:
            log.error(f"⚠️ Ошибка (400): {e.message}")
        else:
            log.error(f"⚠️ Ошибка ({e.status}): {e.message}")
    return None


log.info("🚀 Oracle Catcher (GitHub Actions Edition) запущен.")
attempt = 0
start_time = time.time()

while True:
    elapsed = time.time() - start_time
    if elapsed > RUN_DURATION:
        log.info(f"⌛ Время работы ({RUN_DURATION} сек) вышло. Завершаем Job.")
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

    instance_id = None
    for ad in ads:
        for (ocpu, mem) in options:
            result = try_launch_instance(ad, ocpu, mem)
            if result == "LIMIT_EXCEEDED":
                log.error("🚫 Аккаунт Oracle не имеет квоты на ARM. Останавливаем ловца.")
                log.error("Зайди в Oracle Console → Limits, Quotas and Usage → запроси увеличение standard-a1-core-count.")
                sys.exit(1)
            if result:
                instance_id = result
                break
        if instance_id:
            break

    if instance_id:
        log.info("🎉 Инстанс создан! Ждём публичный IP...")
        public_ip = get_instance_ip(instance_id)
        log.info(f"🌐 Публичный IP: {public_ip}")
        log.info(f"🔑 SSH команда: ssh ubuntu@{public_ip}")

        subject = "✅ Oracle ARM сервер пойман!"
        body = f"""Oracle Catcher успешно поймал бесплатный ARM инстанс!

Данные для подключения:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Instance ID : {instance_id}
Публичный IP: {public_ip}
SSH команда : ssh ubuntu@{public_ip}
Region      : {config['region']}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Сервер: {DISPLAY_NAME} ({OCPUS} OCPU, {MEMORY_GB} GB RAM)
"""
        send_email(subject, body)
        sys.exit(0)

    # Jitter чтобы скрыть паттерн бота
    wait = random.randint(MIN_WAIT, MAX_WAIT) + random.randint(1, 15)
    log.info(f"⏳ Следующая попытка через {wait} сек...")
    time.sleep(wait)
