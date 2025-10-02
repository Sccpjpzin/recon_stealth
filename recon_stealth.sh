#!/bin/bash

# Script de Reconhecimento Stealth - Versão Bash Simplificada
# Desenvolvido para J&B Dev - João
# Versão: 1.0

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para exibir banner
show_banner() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "      RECONHECIMENTO STEALTH - J&B DEV"
    echo "=================================================="
    echo -e "${NC}"
}

# Função para logging
log_message() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$OUTPUT_DIR/recon.log"
    echo -e "${GREEN}[+]${NC} $message"
}

# Função para erro
error_message() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] ERROR: $message" >> "$OUTPUT_DIR/recon.log"
    echo -e "${RED}[!]${NC} $message"
}

# Função para delay aleatório
random_delay() {
    local min_delay=3
    local max_delay=8
    local delay=$((min_delay + RANDOM % (max_delay - min_delay + 1)))
    echo -e "${YELLOW}[*]${NC} Aguardando $delay segundos para evitar detecção..."
    sleep $delay
}

# Função para criar diretórios
setup_directories() {
    local domain="$1"
    local timestamp=$(date "+%Y%m%d_%H%M%S")
    OUTPUT_DIR="recon_${domain}_${timestamp}"
    
    mkdir -p "$OUTPUT_DIR"/{nmap,whatweb,waf,nuclei,logs}
    log_message "Diretórios criados em: $OUTPUT_DIR"
}

# Função para detecção de WAF
detect_waf() {
    local target="$1"
    log_message "Iniciando detecção de WAF em: $target"
    
    local output_file="$OUTPUT_DIR/waf/waf_$target.txt"
    
    # Tentar HTTPS primeiro, depois HTTP se falhar
    if ! wafw00f -v "https://$target" > "$output_file" 2>&1; then
        wafw00f -v "http://$target" > "$output_file" 2>&1
    fi
    
    log_message "WAF detection salvo em: $output_file"
    random_delay
}

# Função para scan Nmap stealth
nmap_stealth_scan() {
    local target="$1"
    log_message "Iniciando Nmap stealth scan em: $target"
    
    local output_file="$OUTPUT_DIR/nmap/nmap_$target.txt"
    
    # Scan stealth otimizado para evasão
    nmap -sS -T1 \
         --scan-delay 4s \
         --max-retries 2 \
         --max-scan-delay 10s \
         -f \
         --source-port 53 \
         --data-length 25 \
         -Pn \
         -sV --version-intensity 2 \
         --script=default,safe \
         -p 21,22,25,53,80,135,139,443,993,995,1433,3306,3389,5432,8080,8443 \
         -oN "$output_file" \
         "$target" 2>/dev/null
    
    log_message "Nmap scan salvo em: $output_file"
    random_delay
}

# Função para detecção de tecnologias web
web_tech_scan() {
    local target="$1"
    log_message "Iniciando detecção de tecnologias em: $target"
    
    local output_file="$OUTPUT_DIR/whatweb/whatweb_$target.json"
    
    whatweb --aggression 1 \
            --wait 3 \
            --read-timeout 30 \
            --max-threads 1 \
            --log-json="$output_file" \
            "https://$target" 2>/dev/null
    
    log_message "Tecnologias web salvas em: $output_file"
    random_delay
}

# Função para scan Nuclei conservador
nuclei_scan() {
    local target="$1"
    log_message "Iniciando Nuclei scan em: $target"
    
    local output_file="$OUTPUT_DIR/nuclei/nuclei_$target.json"
    
    nuclei -u "https://$target" \
           -t ~/nuclei-templates/http/technologies/ \
           -t ~/nuclei-templates/http/exposures/ \
           -severity info,low \
           -rate-limit 20 \
           -timeout 30 \
           -retries 1 \
           -json \
           -o "$output_file" 2>/dev/null
    
    log_message "Nuclei scan salvo em: $output_file"
    random_delay
}

# Função para reconhecimento adicional
additional_recon() {
    local target="$1"
    log_message "Executando reconhecimento adicional: $target"
    
    # SSL/TLS info
    local ssl_output="$OUTPUT_DIR/logs/ssl_$target.txt"
    echo | openssl s_client -connect "$target:443" -servername "$target" 2>/dev/null > "$ssl_output"
    
    # Headers HTTP
    local headers_output="$OUTPUT_DIR/logs/headers_$target.txt"
    curl -I -s --connect-timeout 30 --max-time 60 "https://$target" > "$headers_output" 2>/dev/null
    
    random_delay
}

# Função principal para processar um domínio
process_domain() {
    local domain="$1"
    
    echo -e "${BLUE}[*] Processando domínio: $domain${NC}"
    echo "=================================================="
    
    detect_waf "$domain"
    nmap_stealth_scan "$domain"
    web_tech_scan "$domain"
    nuclei_scan "$domain"
    additional_recon "$domain"
    
    echo -e "${GREEN}[+] Reconhecimento completo para: $domain${NC}"
}

# Função para gerar relatório
generate_report() {
    local report_file="$OUTPUT_DIR/RELATORIO.txt"
    
    {
        echo "RELATÓRIO DE RECONHECIMENTO STEALTH"
        echo "===================================="
        echo "Data: $(date)"
        echo "Diretório: $OUTPUT_DIR"
        echo ""
        echo "ARQUIVOS GERADOS:"
        echo "-----------------"
        find "$OUTPUT_DIR" -type f -name "*.txt" -o -name "*.json" | sort
        echo ""
        echo "PRÓXIMOS PASSOS:"
        echo "1. Analisar portas abertas no Nmap"
        echo "2. Verificar tecnologias no WhatWeb"
        echo "3. Revisar WAF detectado"
        echo "4. Examinar resultados do Nuclei"
        echo ""
    } > "$report_file"
    
    log_message "Relatório gerado: $report_file"
}

# Função para verificar dependências
check_dependencies() {
    local deps=("nmap" "whatweb" "wafw00f" "nuclei" "curl" "openssl")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error_message "Dependências não encontradas: ${missing[*]}"
        echo "Instale com:"
        echo "sudo apt update && sudo apt install nmap whatweb curl openssl"
        echo "Para wafw00f e nuclei, consulte a documentação oficial."
        exit 1
    fi
}

# Função principal
main() {
    show_banner
    
    if [ $# -lt 2 ]; then
        echo "Uso:"
        echo "  $0 -d dominio.com              # Scan de domínio único"
        echo "  $0 -f lista_dominios.txt       # Scan de lista"
        echo ""
        echo "Exemplos:"
        echo "  $0 -d exemplo.com"
        echo "  $0 -f meus_subdominios.txt"
        exit 1
    fi
    
    check_dependencies
    
    case "$1" in
        -d|--domain)
            local domain="$2"
            setup_directories "$domain"
            process_domain "$domain"
            generate_report
            ;;
        -f|--file)
            local file="$2"
            if [ ! -f "$file" ]; then
                error_message "Arquivo não encontrado: $file"
                exit 1
            fi
            
            setup_directories "batch_scan"
            
            while IFS= read -r domain; do
                [ -z "$domain" ] && continue
                process_domain "$domain"
                
                # Delay maior entre domínios
                echo -e "${YELLOW}[*]${NC} Pausa entre domínios..."
                sleep $((10 + RANDOM % 10))
            done < "$file"
            
            generate_report
            ;;
        *)
            error_message "Opção inválida: $1"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}[+] RECONHECIMENTO CONCLUÍDO!${NC}"
    echo -e "${GREEN}[+] Resultados em: $OUTPUT_DIR${NC}"
}

# Executar script
main "$@"
