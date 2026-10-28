# Evidência — execução aprovada após a correção

Segunda parte do Requisito 5: corrigir a dependência vulnerável e comprovar a execução
bem-sucedida da pipeline.

- **Pull Request:** [#1](https://github.com/MilitaoPedro/DevOpsWorkflow/pull/1)
- **Commit da correção:** `14f666e`
- **Execução da pipeline:** [run #40626106821](https://github.com/MilitaoPedro/DevOpsWorkflow/actions/runs/40626106821)
  — resultado: ✅ **success**

## Correção aplicada

| Pacote | Antes | Depois | CVE removida |
| ------ | ----- | ------ | ------------ |
| `minimist` | 1.2.0 | **1.2.6** | CVE-2021-44906 (CRITICAL) |
| `lodash` | 4.17.15 | **4.18.1** | CVE-2020-8203, CVE-2021-23337, CVE-2026-4800, NSWG-ECO-516 (HIGH) |

> **Observação relevante:** a versão 4.17.21 do `lodash` — normalmente considerada a
> "versão corrigida" — **ainda possui a CVE-2026-4800** (HIGH, corrigida apenas na
> 4.18.0). A primeira tentativa de correção usou 4.17.21 e o gate **continuou falhando**,
> o que na prática demonstra que a verificação é real e não apenas decorativa. A correção
> só foi aceita após atualizar para 4.18.1.

## Verificação da correção

Mesmo comando do job `trivy`:

```bash
trivy fs --scanners vuln --severity CRITICAL,HIGH --ignore-unfixed --exit-code 1 .
```

| | Antes da correção | Depois da correção |
| --- | --- | --- |
| Total CRITICAL/HIGH | 5 (1 CRITICAL, 4 HIGH) | **0** |
| Código de saída | `1` (bloqueia) | **`0` (passa)** |

```
Report Summary
┌───────────────────┬──────┬─────────────────┐
│      Target       │ Type │ Vulnerabilities │
├───────────────────┼──────┼─────────────────┤
│ package-lock.json │ npm  │        0        │
└───────────────────┴──────┴─────────────────┘
```

## Checks do Pull Request após a correção

| Check | Antes (commit `8dab84c`) | Depois (commit `14f666e`) |
| ----- | ------------------------ | ------------------------- |
| `gitleaks` | ✅ success | ✅ success |
| `sonarcloud` | ✅ success | ✅ success |
| `trivy` | ❌ **failure** | ✅ **success** |
| `sbom` | ✅ success | ✅ success |
| `publish` | ⏭️ skipped | ⏭️ skipped (só roda em push na `main`) |

Estado do PR: de **`unstable`** (bloqueado) para **`clean`** (liberado para merge).

## Resumo do ciclo completo

| Etapa | Commit | Execução | Resultado |
| ----- | ------ | -------- | --------- |
| Vulnerabilidade introduzida | `8dab84c` | [run #40624823499](https://github.com/MilitaoPedro/DevOpsWorkflow/actions/runs/40624823499) | ❌ bloqueado |
| Correção aplicada | `14f666e` | [run #40626106821](https://github.com/MilitaoPedro/DevOpsWorkflow/actions/runs/40626106821) | ✅ aprovado |

A versão vulnerável **nunca foi publicada no registry**: o job `publish` depende de
`trivy` e ficou como `skipped` na execução que falhou.
