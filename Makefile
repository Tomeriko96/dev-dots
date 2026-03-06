base:
	mkdir -p .devcontainer/base
	devcontainer up --workspace-folder . --config .devcontainer/base/devcontainer.json --id-label name=devcontainer-base
	devcontainer exec --workspace-folder . --config .devcontainer/base/devcontainer.json --id-label name=devcontainer-base bash

python-uv:
	mkdir -p .devcontainer/python-uv
	devcontainer up --workspace-folder . --config .devcontainer/python-uv/devcontainer.json --id-label name=devcontainer-python-uv
	devcontainer exec --workspace-folder . --config .devcontainer/python-uv/devcontainer.json --id-label name=devcontainer-python-uv bash

slidev:
	mkdir -p .devcontainer/slidev
	devcontainer up --workspace-folder . --config .devcontainer/slidev/devcontainer.json --id-label name=devcontainer-slidev
	devcontainer exec --workspace-folder . --config .devcontainer/slidev/devcontainer.json --id-label name=devcontainer-slidev bash
