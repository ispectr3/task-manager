"""
Corrige sintaxe do helm_release para o Helm provider v3+.

Converte:
    set = [{
      name  = "loki.image.tag"
      value = "2.9.3"
    }]

Para:
    set {
      name  = "loki.image.tag"
      value = "2.9.3"
    }

Uso:
    python3 fix_helm_set.py main.tf
"""

import re
import sys


def convert_set_argument(text: str) -> str:
    # Captura "set = [ ... ]" (multilinha), incluindo um ou mais objetos {...}
    pattern = re.compile(r"set\s*=\s*\[(.*?)\]\s*\n?", re.DOTALL)

    def replace(match: re.Match) -> str:
        body = match.group(1)
        objs = re.findall(r"\{(.*?)\}", body, re.DOTALL)
        blocks = []
        for obj in objs:
            lines = [l.strip() for l in obj.strip().splitlines() if l.strip()]
            inner = "\n".join(f"    {l}" for l in lines)
            blocks.append(f"set {{\n{inner}\n  }}")
        return "\n".join(blocks) + "\n"

    return pattern.sub(replace, text)


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "main.tf"

    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    if "set = [" not in content and "set=[" not in content:
        print("Nenhuma ocorrência de 'set = [...]' encontrada. Nada foi alterado.")
        return

    fixed = convert_set_argument(content)

    backup_path = path + ".bak"
    with open(backup_path, "w", encoding="utf-8") as f:
        f.write(content)

    with open(path, "w", encoding="utf-8") as f:
        f.write(fixed)

    print(f"Backup salvo em: {backup_path}")
    print(f"Arquivo corrigido: {path}")
    print("Rode em seguida: terraform fmt && terraform validate")


if __name__ == "__main__":
    main()