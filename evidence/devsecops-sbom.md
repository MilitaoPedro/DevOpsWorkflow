# Evidência — SBOM gerado e publicado como artifact

Requisito 4: gerar um Software Bill of Materials da imagem Docker, com componentes e
versões, e publicá-lo como artifact da execução do GitHub Actions.

## Artifact publicado

Execução: [run #40623709633](https://github.com/MilitaoPedro/DevOpsWorkflow/actions/runs/40623709633)

| Artifact | Conteúdo | Tamanho |
| -------- | -------- | ------- |
| `sbom-image` | `sbom-image.cdx.json` (CycloneDX) + `sbom-image.spdx.json` (SPDX) | 58.715 bytes |

Disponível em **Actions → execução → Artifacts → `sbom-image`**.

## Conteúdo do SBOM

> Os números abaixo foram obtidos reproduzindo localmente o mesmo comando do Syft sobre
> a imagem construída pelo `Dockerfile` deste repositório (o artifact do CI é gerado da
> mesma forma). Para conferir o arquivo exato da execução, baixe o artifact
> `sbom-image` em **Actions → run #40623709633 → Artifacts**.

### CycloneDX

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.7",
  "components": [ ... ]
}
```

- **242 componentes** listados, cada um com nome e versão.

Exemplos de componentes identificados:

| Componente | Versão | Tipo |
| ---------- | ------ | ---- |
| `alpine-baselayout` | 3.7.2-r0 | library |
| `alpine-keys` | 2.6-r0 | library |
| `alpine-release` | 3.23.7-r0 | library |
| `apk-tools` | 3.0.8-r0 | library |
| `accepts` | 1.3.8 | library |

### SPDX

```json
{
  "spdxVersion": "SPDX-2.3",
  "packages": [ ... ]
}
```

- **90 pacotes** listados.

## Como o SBOM é gerado

```yaml
- name: Gerar SBOM com Syft (CycloneDX)
  uses: anchore/sbom-action@66cbf4bc1f1c0d2edc94016e65bc221b6bb0ad6c # v0.24.3
  with:
    image: devopsworkflow:sbom
    format: cyclonedx-json
    output-file: sbom-image.cdx.json

- name: Publicar SBOM como artifact
  uses: actions/upload-artifact@cf430e030ddbb5b0abf93d22962f4752f3646cd9 # v7.0.2
  with:
    name: sbom-image
    path: |
      sbom-image.cdx.json
      sbom-image.spdx.json
    if-no-files-found: error
```

O SBOM é gerado em **dois formatos** para atender aos consumidores mais comuns: CycloneDX
(usado por scanners e políticas de segurança) e SPDX (padrão ISO/IEC 5962).
