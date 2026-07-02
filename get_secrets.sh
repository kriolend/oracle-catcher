#!/bin/bash

# Скрипт для извлечения ключей из Ansible Vault

echo -e "\033[1;33mВведи пароль от Ansible Vault (ввод скрыт):\033[0m"
read -s VAULT_PASS
echo

# Сохраняем пароль во временный файл
echo "$VAULT_PASS" > .tmp_vault_pass

# Пытаемся расшифровать vault.yml
VAULT_DATA=$(ansible-vault view ansible/inventory/group_vars/all/vault.yml --vault-password-file .tmp_vault_pass 2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "\033[1;31m❌ Неверный пароль от Vault!\033[0m"
    rm -f .tmp_vault_pass
    exit 1
fi

rm -f .tmp_vault_pass
echo -e "\033[1;32m✅ Пароль верный! Вот готовые секреты для копирования в GitHub:\033[0m"
echo "======================================================"

# Извлекаем значения (убираем лишние кавычки и пробелы)
USER_OCID=$(echo "$VAULT_DATA" | grep 'vault_oracle_user_ocid:' | awk '{print $2}' | tr -d '"')
TENANCY_OCID=$(echo "$VAULT_DATA" | grep 'vault_oracle_tenancy_ocid:' | awk '{print $2}' | tr -d '"')
FINGERPRINT=$(echo "$VAULT_DATA" | grep 'vault_oracle_fingerprint:' | awk '{print $2}' | tr -d '"')
SUBNET_OCID=$(echo "$VAULT_DATA" | grep 'vault_oracle_subnet_ocid:' | awk '{print $2}' | tr -d '"')

# SSH ключ может содержать пробелы, поэтому извлекаем аккуратно
SSH_KEY=$(echo "$VAULT_DATA" | grep 'vault_oracle_ssh_public_key:' | cut -d':' -f2- | sed -e 's/^[[:space:]]*"//' -e 's/"$//')

echo -e "\033[1;36mORACLE_USER_OCID:\033[0m"
echo "$USER_OCID"
echo ""

echo -e "\033[1;36mORACLE_TENANCY_OCID:\033[0m"
echo "$TENANCY_OCID"
echo ""

echo -e "\033[1;36mORACLE_FINGERPRINT:\033[0m"
echo "$FINGERPRINT"
echo ""

echo -e "\033[1;36mORACLE_SUBNET_OCID:\033[0m"
echo "$SUBNET_OCID"
echo ""

echo -e "\033[1;36mORACLE_SSH_PUBLIC_KEY:\033[0m"
echo "$SSH_KEY"
echo ""

echo -e "\033[1;36mORACLE_API_KEY:\033[0m"
cat ansible/roles/oracle_catcher/files/oracle_api_key.pem
echo ""

echo "======================================================"
echo "Публичные настройки из oracle.yml:"
echo "ORACLE_REGION: eu-frankfurt-1"
echo "ORACLE_AVAILABILITY_DOMAINS: utzh:EU-FRANKFURT-1-AD-1, utzh:EU-FRANKFURT-1-AD-2, utzh:EU-FRANKFURT-1-AD-3"
echo "ORACLE_IMAGE_ID: ocid1.image.oc1.eu-frankfurt-1.aaaaaaaapli4odzd45utz5wtjkqiu5xzzu5kkcwlgvljxuf6qbgytl26hxza"
echo "ORACLE_SHAPE: VM.Standard.A1.Flex"
echo "ORACLE_OCPUS: 4"
echo "ORACLE_MEMORY_GB: 24"
echo "ORACLE_INSTANCE_DISPLAY_NAME: Oracle-ARM-Master"
echo "======================================================"
