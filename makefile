brewfile:=Brewfile
python_version:=3.9.1
current:=$(shell cat .python-version)
repo:=$(shell basename $(CURDIR))
stack_file:=./ops/local/stack.yaml
scale:=2

# private ---------------------------------------------------------------------

--install:
	@echo
	@brew bundle install --file=$(brewfile)

--venv:
	@echo
	@pyenv install $(python_version) -s
	@pyenv virtualenv -f -q $(python_version) $(repo) 1> /dev/null
	@pyenv local $(repo)
	@pip install -q --upgrade pip
	@pip install -qr requirements.txt

--hooks:
	@git add .
	@pre-commit autoupdate
	@pre-commit install
	@echo
	@-pre-commit

--references:
	@sed -i '' s/$(current)/$(repo)/g README.md
	@sed -i '' s/$(current)/$(repo)/g .python-version

# public ----------------------------------------------------------------------

list:
	@echo
	@brew bundle list --file=$(brewfile)
	@echo
	@cat requirements.txt

init: --install rename --hooks

up-db:
	@echo
	@KONG_DATABASE=postgres docker compose --profile database --file "$(stack_file)" up \
		--scale kong=$(scale) \
		--detach

up-dbless:
	@echo
	@docker compose --file "$(stack_file)" up \
		--scale kong=$(scale) \
		--detach

ps:
	@echo
	@docker ps \
		--format="table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.State}}\t{{.Networks}}" \
		--filter 'network=local_kong' \
		--all

down:
	@echo
	@docker compose --file "$(stack_file)" down --remove-orphans

rename: --venv --references
