#!/usr/bin/env python3

"""
Script de Reconhecimento Lógico Stealth
Desenvolvido para J&B Dev - João
Versão: 1.0

Este script executa reconhecimento detalhado em subdomínios de forma
cautelosa para evitar detecção por WAF e sistemas de monitoramento.

Uso:
    python3 recon_stealth.py -d dominio.com
    python3 recon_stealth.py -f lista_subdominios.txt
"""

import subprocess
import time
import os
import sys
import argparse
import json
import random
from datetime import datetime
from pathlib import Path

class StealthRecon:
    def __init__(self):
        self.output_dir = None
        self.target_domain = None
        self.delay_min = 10  # Delay mínimo entre comandos
        self.delay_max = 25  # Delay máximo entre comandos
        
    def setup_output_directory(self, domain):
        """Cria diretório de saída organizado"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.output_dir = Path(f"recon_{domain}_{timestamp}")
        self.output_dir.mkdir(exist_ok=True)
        
        # Criar subdiretórios
        (self.output_dir / "nmap").mkdir(exist_ok=True)
        (self.output_dir / "web_tech").mkdir(exist_ok=True)
        (self.output_dir / "waf_detection").mkdir(exist_ok=True)
        (self.output_dir / "nuclei").mkdir(exist_ok=True)
        (self.output_dir / "logs").mkdir(exist_ok=True)
        
        print(f"[+] Diretório de saída criado: {self.output_dir}")

    def random_delay(self):
        """Introduz delay aleatório para evitar detecção"""
        delay = random.uniform(self.delay_min, self.delay_max)
        print(f"[*] Aguardando {delay:.1f} segundos...")
        time.sleep(delay)

    def log_command(self, command, output_file=None):
        """Registra comandos executados em log"""
        log_file = self.output_dir / "logs" / "commands.log"
        with open(log_file, "a") as f:
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            f.write(f"[{timestamp}] {command}\n")
            if output_file:
                f.write(f"    Output: {output_file}\n")

    def run_command(self, command, output_file=None, capture_output=True):
        """Executa comando de forma segura com logging"""
        print(f"[*] Executando: {command}")
        self.log_command(command, output_file)
        
        try:
            if capture_output and output_file:
                with open(output_file, "w") as f:
                    result = subprocess.run(command, shell=True, stdout=f, stderr=subprocess.PIPE, text=True, timeout=600)
            else:
                result = subprocess.run(command, shell=True, capture_output=capture_output, text=True, timeout=600)
            
            if result.returncode != 0 and result.stderr:
                print(f"[!] Erro no comando: {result.stderr}")
                return False
            
            print(f"[+] Comando concluído com sucesso")
            return True
            
        except subprocess.TimeoutExpired:
            print(f"[!] Comando excedeu timeout de 10 minutos")
            return False
        except Exception as e:
            print(f"[!] Erro ao executar comando: {e}")
            return False

    def nmap_stealth_scan(self, target):
        """Executa scan stealth do nmap com técnicas de evasão"""
        print(f"\n[*] Iniciando scan stealth do Nmap em: {target}")
        
        output_file = self.output_dir / "nmap" / f"nmap_{target.replace('.', '_')}.txt"
        
        # Comando nmap otimizado para evasão de WAF
        nmap_cmd = (
            f"nmap -sS -T1 "  # SYN stealth scan, timing mais lento
            f"--scan-delay 10s "  # 10 segundos entre cada probe
            f"--max-retries 2 "  # Máximo 2 tentativas
            f"--max-scan-delay 10s "  # Delay máximo de 10s
            f"-f "  # Fragmentar pacotes
            f"--source-port 53 "  # Usar porta 53 como origem (DNS)
            f"--data-length 25 "  # Adicionar dados aleatórios
            f"-Pn "  # Não fazer ping discovery
            f"-sV --version-intensity 2 "  # Detecção de versão conservadora
            f"--script=default,safe "  # Scripts seguros apenas
            f"-p 21,22,23,25,53,80,110,135,139,143,443,993,995,1433,3306,3389,5432,8080,8443 "  # Portas comuns
            f"-oN {output_file} "
            f"{target}"
        )
        
        success = self.run_command(nmap_cmd, output_file)
        
        if success:
            print(f"[+] Scan Nmap salvo em: {output_file}")
        
        self.random_delay()
        return success

    def detect_waf(self, target):
        """Detecta WAF usando wafw00f"""
        print(f"\n[*] Detectando WAF em: {target}")
        
        output_file = self.output_dir / "waf_detection" / f"waf_{target.replace('.', '_')}.txt"
        
        waf_cmd = f"wafw00f -v https://{target}"
        
        success = self.run_command(waf_cmd, output_file)
        
        if success:
            print(f"[+] Detecção de WAF salva em: {output_file}")
        
        self.random_delay()
        return success

    def web_technology_detection(self, target):
        """Detecta tecnologias web usando whatweb"""
        print(f"\n[*] Detectando tecnologias web em: {target}")
        
        output_file = self.output_dir / "web_tech" / f"whatweb_{target.replace('.', '_')}.json"
        
        # Usar whatweb com configurações cautelosas
        whatweb_cmd = (
            f"whatweb "
            f"--aggression 1 "  # Nível de agressividade baixo
            f"--wait 10 "  # Aguardar 10 segundos entre requests
            f"--read-timeout 30 "  # Timeout de leitura
            f"--max-threads 1 "  # Apenas 1 thread
            f"--log-json {output_file} "
            f"https://{target}"
        )
        
        success = self.run_command(whatweb_cmd)
        
        if success:
            print(f"[+] Tecnologias web detectadas e salvas em: {output_file}")
            
        self.random_delay()
        return success

    def nuclei_scan(self, target):
        """Executa scan nuclei com templates conservadores"""
        print(f"\n[*] Executando scan Nuclei em: {target}")
        
        output_file = self.output_dir / "nuclei" / f"nuclei_{target.replace('.', '_')}.json"
        
        # Usar apenas templates seguros e de reconhecimento
        nuclei_cmd = (
            f"nuclei "
            f"-u https://{target} "
            f"-t /home/kali/nuclei-templates/http/technologies/ "  # Apenas detecção de tecnologias
            f"-t /home/kali/nuclei-templates/http/exposures/ "     # Exposições básicas
            f"-t /home/kali/nuclei-templates/http/misconfiguration/ "  # Misconfiguração
            f"-severity info,low "  # Apenas severidade baixa
            f"-rate-limit 10 "  # Máximo 30 requests por minuto
            f"-timeout 30 "  # Timeout de 30s
            f"-retries 1 "  # Apenas 1 retry
            f"-json "
            f"-o {output_file}"
        )
        
        success = self.run_command(nuclei_cmd)
        
        if success:
            print(f"[+] Scan Nuclei salvo em: {output_file}")
        
        self.random_delay()
        return success

    def additional_recon(self, target):
        """Reconhecimento adicional discreto"""
        print(f"\n[*] Executando reconhecimento adicional em: {target}")
        
        # Verificar certificados SSL
        ssl_output = self.output_dir / "logs" / f"ssl_{target.replace('.', '_')}.txt"
        ssl_cmd = f"openssl s_client -connect {target}:443 -servername {target} < /dev/null"
        self.run_command(ssl_cmd, ssl_output)
        
        self.random_delay()
        
        # Verificar cabeçalhos HTTP
        headers_output = self.output_dir / "logs" / f"headers_{target.replace('.', '_')}.txt"
        headers_cmd = f"curl -I -s --connect-timeout 30 --max-time 60 https://{target}"
        self.run_command(headers_cmd, headers_output)
        
        self.random_delay()

    def process_single_domain(self, domain):
        """Processa um único domínio"""
        print(f"\n{'='*60}")
        print(f"[*] Iniciando reconhecimento de: {domain}")
        print(f"{'='*60}")
        
        self.target_domain = domain
        
        # Executar todas as fases de reconhecimento
        self.detect_waf(domain)
        self.nmap_stealth_scan(domain)
        self.web_technology_detection(domain)
        self.nuclei_scan(domain)
        self.additional_recon(domain)
        
        print(f"\n[+] Reconhecimento completo para {domain}")

    def process_domain_list(self, domains_file):
        """Processa lista de domínios de um arquivo"""
        try:
            with open(domains_file, 'r') as f:
                domains = [line.strip() for line in f if line.strip()]
            
            print(f"[*] Processando {len(domains)} domínios do arquivo: {domains_file}")
            
            for i, domain in enumerate(domains, 1):
                print(f"\n[*] Processando domínio {i}/{len(domains)}: {domain}")
                self.process_single_domain(domain)
                
                # Delay maior entre domínios diferentes
                if i < len(domains):
                    extended_delay = random.uniform(10, 20)
                    print(f"[*] Pausa entre domínios: {extended_delay:.1f} segundos")
                    time.sleep(extended_delay)
                    
        except FileNotFoundError:
            print(f"[!] Arquivo não encontrado: {domains_file}")
            return False
        except Exception as e:
            print(f"[!] Erro ao processar arquivo: {e}")
            return False
        
        return True

    def generate_summary_report(self):
        """Gera relatório resumo dos resultados"""
        print(f"\n[*] Gerando relatório resumo...")
        
        report_file = self.output_dir / "RELATORIO_RESUMO.txt"
        
        with open(report_file, "w") as f:
            f.write("RELATÓRIO DE RECONHECIMENTO STEALTH\n")
            f.write("="*50 + "\n")
            f.write(f"Data/Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Target: {self.target_domain}\n")
            f.write("\n")
            
            # Listar arquivos gerados
            f.write("ARQUIVOS GERADOS:\n")
            f.write("-"*20 + "\n")
            
            for subdir in ["nmap", "web_tech", "waf_detection", "nuclei", "logs"]:
                subdir_path = self.output_dir / subdir
                if subdir_path.exists():
                    files = list(subdir_path.glob("*"))
                    if files:
                        f.write(f"\n{subdir.upper()}:\n")
                        for file in files:
                            f.write(f"  - {file.name}\n")
            
            f.write("\n" + "="*50 + "\n")
            f.write("PRÓXIMOS PASSOS RECOMENDADOS:\n")
            f.write("1. Analisar resultados do Nmap para portas abertas\n")
            f.write("2. Verificar tecnologias detectadas pelo WhatWeb\n")
            f.write("3. Revisar detecção de WAF antes de testes intrusivos\n")
            f.write("4. Analisar resultados do Nuclei para vulnerabilidades\n")
            f.write("5. Examinar certificados SSL e cabeçalhos HTTP\n")
        
        print(f"[+] Relatório salvo em: {report_file}")

def main():
    parser = argparse.ArgumentParser(
        description="Script de Reconhecimento Lógico Stealth - J&B Dev",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos de uso:
  python3 recon_stealth.py -d exemplo.com
  python3 recon_stealth.py -f subdominios.txt

Notas importantes:
- O script usa técnicas de evasão para evitar detecção por WAF
- Inclui delays aleatórios entre comandos
- Todos os resultados são salvos em diretório organizado
- Prioriza eficiência sobre velocidade para máxima discrição
        """
    )
    
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-d", "--domain", help="Domínio único para reconhecimento")
    group.add_argument("-f", "--file", help="Arquivo com lista de domínios")
    
    parser.add_argument("--delay-min", type=int, default=2, 
                       help="Delay mínimo entre comandos (padrão: 2s)")
    parser.add_argument("--delay-max", type=int, default=8,
                       help="Delay máximo entre comandos (padrão: 8s)")
    
    args = parser.parse_args()
    
    # Verificar se estamos rodando no Kali Linux
    try:
        subprocess.run(["which", "nmap"], check=True, capture_output=True)
        subprocess.run(["which", "whatweb"], check=True, capture_output=True) 
        subprocess.run(["which", "wafw00f"], check=True, capture_output=True)
        subprocess.run(["which", "nuclei"], check=True, capture_output=True)
    except subprocess.CalledProcessError:
        print("[!] Uma ou mais ferramentas necessárias não estão instaladas:")
        print("    - nmap, whatweb, wafw00f, nuclei")
        print("    Instale com: sudo apt update && sudo apt install nmap whatweb")
        print("    Para nuclei: https://github.com/projectdiscovery/nuclei")
        sys.exit(1)
    
    # Inicializar reconhecimento
    recon = StealthRecon()
    recon.delay_min = args.delay_min
    recon.delay_max = args.delay_max
    
    print("[*] Iniciando Reconhecimento Stealth - J&B Dev")
    print("[*] Configuração: delays entre comandos de {}s a {}s".format(
        args.delay_min, args.delay_max))
    
    if args.domain:
        # Modo domínio único
        recon.setup_output_directory(args.domain)
        recon.process_single_domain(args.domain)
    else:
        # Modo lista de domínios
        recon.setup_output_directory("batch_scan")
        recon.process_domain_list(args.file)
    
    # Gerar relatório final
    recon.generate_summary_report()
    
    print(f"\n[+] RECONHECIMENTO CONCLUÍDO!")
    print(f"[+] Todos os resultados estão em: {recon.output_dir}")
    print(f"[+] Verifique o RELATORIO_RESUMO.txt para próximos passos")

if __name__ == "__main__":
    main()
