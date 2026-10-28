# Evidência — bloqueio da pipeline por dependência vulnerável

Requisito 5: introduzir intencionalmente uma dependência com CVE conhecida e correção
disponível, comprovar a falha da verificação e o bloqueio do merge.

## O que foi introduzido

Branch de teste: `demo/vulnerabilidade` (commit `8dab84c`)

```json
{
  "dependencies": {
    "express": "^4.21.2",
    "lodash": "4.17.15",
    "minimist": "1.2.0"
  }
}
```

Ambas as versões possuem CVE conhecida **com correção disponível** — exatamente o critério
de bloqueio do Trivy (`--ignore-unfixed`).

## Resultado da verificação

Comando idêntico ao executado pelo job `trivy` do pipeline:

```bash
trivy fs --scanners vuln --severity CRITICAL,HIGH --ignore-unfixed --exit-code 1 .
```

```
Total: 5 (HIGH: 4, CRITICAL: 1)

┌──────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┐
│ Library  │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │
├──────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┤
│ lodash   │ CVE-2020-8203  │ HIGH     │ fixed  │ 4.17.15           │ 4.17.19       │
│          │ CVE-2021-23337 │ HIGH     │ fixed  │ 4.17.15           │ 4.17.21       │
│          │ CVE-2026-4800  │ HIGH     │ fixed  │ 4.17.15           │ 4.18.0        │
│          │ NSWG-ECO-516   │ HIGH     │ fixed  │ 4.17.15           │ >=4.17.19     │
├──────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┤
│ minimist │ CVE-2021-44906 │ CRITICAL │ fixed  │ 1.2.0             │ 1.2.6, 0.2.4  │
└──────────┴────────────────┴──────────┴────────┴───────────────────┴───────────────┘
```

**Código de saída: `1`** — a verificação falha, como esperado.

```
$ echo $?
1
```

## Consequências do bloqueio

1. O job `trivy` falha.
2. O job `publish` **não executa**, porque declara
   `needs: [gitleaks, sonarcloud, trivy]` — a imagem vulnerável **não é publicada** no
   registry.
3. Com a proteção de branch configurada (ver README), o merge do Pull Request fica
   bloqueado enquanto o check obrigatório estiver falhando.

## Detalhamento das vulnerabilidades

| Pacote | Versão | CVE | Severidade | Correção |
| ------ | ------ | --- | ---------- | -------- |
| `minimist` | 1.2.0 | CVE-2021-44906 | **CRITICAL** | 1.2.6 |
| `lodash` | 4.17.15 | CVE-2020-8203 | HIGH | 4.17.19 |
| `lodash` | 4.17.15 | CVE-2021-23337 | HIGH | 4.17.21 |
| `lodash` | 4.17.15 | CVE-2026-4800 | HIGH | 4.18.0 |
| `lodash` | 4.17.15 | NSWG-ECO-516 | HIGH | >=4.17.19 |

A correção e a comprovação da execução aprovada estão em
[`devsecops-correcao.md`](devsecops-correcao.md).
