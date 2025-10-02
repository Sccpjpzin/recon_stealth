#!/bin/bash

# Script de Instalação - Reconhecimento Stealth
# J&B Dev - Setup Automatizado para Kali Linux
# Versão: 1.0

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Função para mostrar banner
show_banner() {
    clear
    echo -e "${BLUE}"
    echo "=================================================="
    echo "     SETUP RECONHECIMENTO STEALTH - J&B DEV"
    echo "=================================================="
    echo -e "${NC}"
    echo "Este script irá configurar todas as dependências"
    echo "necessárias para o reconhecimento stealth."
    echo ""
}

# Função para logging
log_message() {
    local message="$1"
    echo -e "${GREEN}[+]${NC} $message"
}

# Função para erro
error_message() {
    local message="$1"
    echo -e "${RED}[!]${NC} $message"
}

# Função para warning
warning_message() {
    local message="$1"
    echo -e "${YELLOW}[*]${NC} $message"
}

# Verificar se é root/sudo
check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        warning_message "Executando como root. Isso é necessário para instalação."
    else
        error_message "Este script precisa ser executado com sudo."
        echo "Uso: sudo ./setup.sh"
        exit 1
    fi
}

# Verificar se é Kali Linux
check_kali() {
    if ! grep -q "Kali" /etc/os-release 2>/dev/null; then
        warning_message "Este script foi desenvolvido para Kali Linux."
        echo "Você está executando em: $(lsb_release -d 2>/dev/null | cut -f2 || echo 'Sistema desconhecido')"
        read -p "Continuar mesmo assim? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Instalação cancelada."
            exit 1
        fi
    else
        log_message "Kali Linux detectado. Prosseguindo..."
    fi
}

# Atualizar sistema
update_system() {
    log_message "Atualizando sistema..."
    apt update -qq
    apt upgrade -y -qq
    log_message "Sistema atualizado com sucesso."
}

# Instalar dependências básicas
install_basic_deps() {
    log_message "Instalando dependências básicas..."
    
    local deps=("nmap" "whatweb" "curl" "openssl" "python3" "python3-pip" "git" "wget")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            warning_message "Instalando: $dep"
            apt install -y "$dep" -qq
        else
            log_message "$dep já está instalado."
        fi
    done
}

# Instalar wafw00f
install_wafw00f() {
    log_message "Instalando wafw00f..."
    
    if command -v wafw00f &> /dev/null; then
        log_message "wafw00f já está instalado."
        return
    fi
    
    cd /tmp
    if [ -d "wafw00f" ]; then
        rm -rf wafw00f
    fi
    
    git clone https://github.com/EnableSecurity/wafw00f.git -q
    cd wafw00f
    python3 setup.py install -q
    
    # Verificar instalação
    if command -v wafw00f &> /dev/null; then
        log_message "wafw00f instalado com sucesso."
    else
        error_message "Falha ao instalar wafw00f."
    fi
    
    cd - > /dev/null
}

# Instalar Nuclei
install_nuclei() {
    log_message "Instalando Nuclei..."
    
    if command -v nuclei &> /dev/null; then
        log_message "Nuclei já está instalado."
    else
        warning_message "Baixando Nuclei..."
        curl -s https://get.nuclei.sh | bash -s -- -i /usr/local/bin/
    fi
    
    # Atualizar templates
    warning_message "Atualizando templates do Nuclei..."
    nuclei -update-templates -silent
    
    if command -v nuclei &> /dev/null; then
        log_message "Nuclei instalado com sucesso."
    else
        error_message "Falha ao instalar Nuclei."
    fi
}

# Instalar outras ferramentas úteis
install_additional_tools() {
    log_message "Instalando ferramentas adicionais..."
    
    # subfinder (útil para enumeração de subdomínios)
    if ! command -v subfinder &> /dev/null; then
        warning_message "Instalando subfinder..."
        GO111MODULE=on go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null
    fi
    
    # httpx (útil para verificar hosts ativos)  
    if ! command -v httpx &> /dev/null; then
        warning_message "Instalando httpx..."
        GO111MODULE=on go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest 2>/dev/null
    fi
    
    log_message "Ferramentas adicionais configuradas."
}

# Configurar permissões e diretórios
setup_permissions() {
    log_message "Configurando permissões..."
    
    # Tornar scripts executáveis
    if [ -f "recon_stealth.py" ]; then
        chmod +x recon_stealth.py
        log_message "recon_stealth.py tornado executável."
    fi
    
    if [ -f "recon_stealth.sh" ]; then
        chmod +x recon_stealth.sh  
        log_message "recon_stealth.sh tornado executável."
    fi
    
    # Criar diretório de trabalho
    if [ ! -d "/opt/recon-stealth" ]; then
        mkdir -p /opt/recon-stealth
        log_message "Diretório /opt/recon-stealth criado."
    fi
    
    # Copiar scripts para diretório sistema (opcional)
    local current_dir=$(pwd)
    if [ -f "$current_dir/recon_stealth.py" ]; then
        cp "$current_dir/recon_stealth.py" /opt/recon-stealth/
        ln -sf /opt/recon-stealth/recon_stealth.py /usr/local/bin/recon-stealth
        log_message "Script principal copiado para /opt/recon-stealth/"
    fi
}

# Verificar instalação
verify_installation() {
    log_message "Verificando instalação..."
    
    local tools=("nmap" "whatweb" "wafw00f" "nuclei" "curl" "openssl")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $tool"
        else
            echo -e "  ${RED}✗${NC} $tool"
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -eq 0 ]; then
        log_message "Todas as ferramentas foram instaladas com sucesso!"
    else
        error_message "Ferramentas não instaladas: ${missing[*]}"
        return 1
    fi
}

# Mostrar informações finais
show_final_info() {
    echo ""
    echo -e "${GREEN}=================================================="
    echo "            INSTALAÇÃO CONCLUÍDA!"
    echo -e "==================================================${NC}"
    echo ""
    echo "Como usar:"
    echo "  python3 recon_stealth.py -d exemplo.com"
    echo "  ./recon_stealth.sh -d exemplo.com"
    echo ""
    echo "Arquivos importantes:"
    echo "  - README.md (instruções detalhadas)"
    echo "  - exemplo_subdominios.txt (lista de exemplo)"
    echo ""
    echo "Próximos passos:"
    echo "  1. Ler o README.md"
    echo "  2. Testar com um domínio de teste"  
    echo "  3. Criar sua lista de subdomínios"
    echo ""
    echo -e "${YELLOW}Lembre-se: Use apenas em ativos autorizados!${NC}"
    echo ""
}

# Função principal
main() {
    show_banner
    
    check_permissions
    check_kali
    
    echo "Iniciando instalação..."
    echo ""
    
    update_system
    install_basic_deps
    install_wafw00f
    install_nuclei
    install_additional_tools
    setup_permissions
    
    echo ""
    if verify_installation; then
        show_final_info
    else
        error_message "Instalação completada com erros. Verifique as dependências manualmente."
        exit 1
    fi
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
