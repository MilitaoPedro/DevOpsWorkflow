# Evidência — bloqueio da pipeline por dependência vulnerável

Requisito 5: introduzir intencionalmente uma dependência com CVE conhecida e correção
disponível, comprovar a falha da verificação e o bloqueio do merge.

- **Pull Request:** [#1](https://github.com/MilitaoPedro/DevOpsWorkflow/pull/1) —
  `demo/vulnerabilidade` → `main`
- **Execução da pipeline:** [run #40624823499](https://github.com/MilitaoPedro/DevOpsWorkflow/actions/runs/40624823499)
  — resultado: ❌ **failure**

## Resultado dos checks no PR

| Check | Resultado |
| ----- | --------- |
| `gitleaks` | ✅ success |
| `sonarcloud` | ✅ success |
| `trivy` | ❌ **failure** |
| `sbom` | ✅ success |
| `publish` | ⏭️ **skipped** (não executou) |

O estado do PR é **`unstable`**, ou seja, com check obrigatório falhando — o merge fica
bloqueado enquanto a proteção de branch estiver configurada.

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

1. O job `trivy` falha — o passo bloqueante
   *"Trivy - dependencias (bloqueia CRITICAL/HIGH com correcao)"* retorna código de saída
   `1`.
2. O job `publish` **não executa** (`skipped`), porque declara
   `needs: [gitleaks, sonarcloud, trivy]` — a imagem vulnerável **não é publicada** no
   registry, atendendo ao requisito de não publicar a versão vulnerável em produção.
3. Com a proteção de branch configurada (ver README), o merge do Pull Request fica
   bloqueado enquanto o check obrigatório estiver falhando.

Detalhe dos jobs na execução do PR:

```
JOB trivy          -> failure
    [ok  ] Checkout do codigo
    [FAIL] Trivy - dependencias (bloqueia CRITICAL/HIGH com correcao)
    [ok  ] Trivy - dependencias (relatorio LOW/MEDIUM, nao bloqueia)
    [--  ] Build da imagem Docker para varredura
    ...
JOB gitleaks       -> success
JOB sonarcloud     -> success
JOB sbom           -> success
JOB publish        -> skipped
```

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
