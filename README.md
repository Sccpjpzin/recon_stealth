# RECONHECIMENTO STEALTH - J&B DEV

## DESCRIÇÃO
Este conjunto de scripts foi desenvolvido especialmente para a J&B Dev realizar reconhecimento lógico de forma cautelosa, evitando detecção por WAF e sistemas de monitoramento.

## ARQUIVOS INCLUÍDOS
- **recon_stealth.py** : Script Python completo (RECOMENDADO)
- **setup.sh** : Script de instalação automatizada  
- **README.md** : Este arquivo de instruções
- **exemplo_subdominios.txt** : Lista de exemplo com 25 subdomínios

## CARACTERÍSTICAS PRINCIPAIS

### TÉCNICAS DE EVASÃO IMPLEMENTADAS:
✓ Timing conservador (-T1 no nmap)
✓ Delays aleatórios entre comandos (3-8 segundos)  
✓ Fragmentação de pacotes (-f)
✓ Source port spoofing (porta 53 - DNS)
✓ Dados aleatórios nos pacotes
✓ Rate limiting em todas as ferramentas
✓ Timeouts conservadores
✓ Máximo de retries limitado

### FERRAMENTAS UTILIZADAS:
- **Nmap**: Port scanning stealth
- **WhatWeb**: Detecção de tecnologias web
- **wafw00f**: Detecção de WAF
- **Nuclei**: Verificações de segurança básicas
- **OpenSSL**: Análise de certificados
- **cURL**: Análise de headers HTTP

## INSTALAÇÃO RÁPIDA

### 1. Baixar os arquivos:
```bash
# Os arquivos principais estão disponíveis para download
# Baixe: recon_stealth.py, setup.sh, exemplo_subdominios.txt
```

### 2. Configurar permissões:
```bash
chmod +x recon_stealth.py
chmod +x setup.sh
```

### 3. Executar instalação:
```bash
sudo ./setup.sh
```

## INSTALAÇÃO MANUAL (se setup.sh falhar)

### 1. Dependências básicas (Kali Linux):
```bash
sudo apt update
sudo apt install nmap whatweb curl openssl python3
```

### 2. Instalar wafw00f:
```bash
git clone https://github.com/EnableSecurity/wafw00f.git
cd wafw00f
sudo python3 setup.py install
```

### 3. Instalar Nuclei:
```bash
curl -s https://get.nuclei.sh | sh
sudo mv nuclei /usr/local/bin/
nuclei -update-templates
```

## USO DO SCRIPT

### Script Python (RECOMENDADO):
```bash
# Scan de domínio único
python3 recon_stealth.py -d exemplo.com

# Scan de lista de domínios
python3 recon_stealth.py -f subdominios.txt

# Com delays personalizados
python3 recon_stealth.py -d exemplo.com --delay-min 5 --delay-max 15
```

## FORMATO DA LISTA DE DOMÍNIOS

Crie um arquivo .txt com um domínio por linha:
```
subdominio1.exemplo.com
subdominio2.exemplo.com
api.exemplo.com
admin.exemplo.com
```

## ESTRUTURA DE SAÍDA

O script cria um diretório organizado:
```
recon_exemplo.com_20241002_141530/
├── nmap/                 # Resultados do Nmap
├── web_tech/            # Detecção de tecnologias (WhatWeb)
├── waf_detection/       # Detecção de WAF (wafw00f)  
├── nuclei/              # Resultados do Nuclei
├── logs/                # Logs detalhados e SSL info
└── RELATORIO_RESUMO.txt # Relatório final
```

## TEMPOS ESTIMADOS

Para cada domínio, considerando técnicas de evasão:
- WAF Detection: ~30-45 segundos
- Nmap Scan: ~5-15 minutos (depende das portas abertas)
- Tech Detection: ~1-2 minutos  
- Nuclei Scan: ~2-5 minutos
- Recon Adicional: ~30 segundos
- Delays entre comandos: ~25-40 segundos

**Total por domínio: 10-25 minutos**
**Para 25 domínios: 4-10 horas**

## DICAS IMPORTANTES

### PARA EVITAR DETECÇÃO:
1. **Execute fora do horário comercial** quando possível
2. **Use VPN ou proxies** se necessário  
3. **Monitore os logs** para verificar se foi detectado
4. **Pause o script** se detectar bloqueios (Ctrl+C)
5. **Varie os horários** entre execuções

### PARA MELHOR PERFORMANCE:
1. **Use o script Python** (mais robusto)
2. **Processe poucos domínios por vez** (5-10 máximo)
3. **Execute em horários de baixo tráfego**
4. **Tenha paciência** - eficiência > velocidade

### EM CASO DE BLOQUEIO:
1. Mude o IP (reinicie VPN/roteador)
2. Aumente os delays no script
3. Aguarde algumas horas antes de tentar novamente
4. Use User-Agent diferente se necessário

## ANÁLISE DOS RESULTADOS

### 1. Verificar WAF Detection:
- Abrir arquivo waf_detection/waf_*.txt
- Identificar tipo de WAF presente
- Ajustar estratégia baseado no WAF

### 2. Analisar Nmap Results:  
- Abrir arquivo nmap/nmap_*.txt
- Identificar portas abertas
- Verificar serviços detectados

### 3. Revisar Web Technologies:
- Abrir arquivo web_tech/whatweb_*.json  
- Identificar CMS, frameworks, servidores
- Procurar versões desatualizadas

### 4. Examinar Nuclei Results:
- Abrir arquivo nuclei/nuclei_*.json
- Verificar configurações expostas  
- Identificar possíveis vulnerabilidades

## PRÓXIMOS PASSOS APÓS O RECONHECIMENTO

1. **Compilar informações** encontradas
2. **Identificar alvos prioritários** (portas abertas, tecnologias)
3. **Planejar testes específicos** baseado nas tecnologias
4. **Verificar credenciais padrão** em serviços identificados
5. **Testar vulnerabilidades conhecidas** das versões encontradas

## TROUBLESHOOTING

### Erro: "Command not found"
- Verificar se todas as dependências estão instaladas
- Verificar PATH das ferramentas

### Timeout nos comandos:
- Aumentar timeouts no script
- Verificar conectividade de rede
- Verificar se o alvo não está bloqueando

### Resultados vazios:
- Verificar se o domínio responde
- Tentar com HTTP em vez de HTTPS
- Verificar logs para erros

### Script muito lento:
- É proposital! Prioriza discrição sobre velocidade
- Para acelerar, reduza delays (com risco de detecção)

## TÉCNICAS DE EVASÃO DETALHADAS

### Nmap Stealth Configuration:
```bash
nmap -sS -T1 \                    # SYN stealth + timing lento
     --scan-delay 3s \            # 3 segundos entre probes  
     --max-retries 2 \            # Máximo 2 tentativas
     --max-scan-delay 10s \       # Delay máximo 10s
     -f \                         # Fragmentar pacotes
     --source-port 53 \           # Porta origem 53 (DNS)
     --data-length 25 \           # Dados aleatórios
     -Pn \                        # Sem ping discovery
     -sV --version-intensity 2    # Detecção conservadora
```

### Outras Evasões:
- **WAF Detection First**: Detecta WAF antes de qualquer teste
- **Rate Limiting**: Máximo 20-30 requests/minuto
- **Random Delays**: 3-8 segundos aleatórios entre comandos
- **Conservative Timeouts**: 30-60 segundos por request
- **Safe Scripts Only**: Apenas scripts "safe" e "default"

## VERIFICAÇÃO DE INSTALAÇÃO

Teste se tudo está funcionando:
```bash
# Verificar dependências
command -v nmap && echo "✓ nmap OK"
command -v whatweb && echo "✓ whatweb OK"
command -v wafw00f && echo "✓ wafw00f OK"
command -v nuclei && echo "✓ nuclei OK"

# Teste básico
python3 recon_stealth.py -d httpbin.org
```

## ÉTICA E LEGALIDADE

⚠️  **IMPORTANTE**: 
- Use apenas em ativos autorizados
- Obtenha permissão por escrito quando necessário
- Respeite termos de uso e políticas
- Este script é para fins educacionais e testes autorizados

## SUPORTE

Para dúvidas ou melhorias no script:
- Revisar logs em logs/commands.log
- Verificar documentação das ferramentas individuais  
- Testar com domínio único primeiro

## COMPARAÇÃO DE PERFORMANCE

| Método | Tempo/Domínio | Detecção | Eficácia |
|--------|---------------|----------|----------|
| Tradicional | 2-5 min | 🔴 ALTO | ⚡ Rápido |
| **Stealth** | **15-25 min** | **🟢 BAIXO** | **🛡️ Discreto** |

---
**Desenvolvido para J&B Dev - Reconhecimento Stealth v1.0**
**🛡️ Stealth First, Speed Second**
