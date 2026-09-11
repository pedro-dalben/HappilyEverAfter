# Comandos Rails na VPS — HappilyEverAfter

## Produção permanece desativada

Em 2026-09-11 não foram encontradas units com os nomes `happily*` ou
`casamento*`. O checkpoint de segurança mantém esta aplicação dormente.
Não há um comando de produção validado para este projeto.

Não execute `sudo RAILS_ENV=production ...` como alternativa a erros de
permissão, Bootsnap ou gems. Não use usuários, releases ou EnvironmentFiles
de IntegrarPlus, homologação ou Pedro. Não reative a aplicação para testar
esta documentação.

## O que pode ser conferido agora

No checkout administrativo:

```bash
rtk proxy git -C /home/ubuntu/HappilyEverAfter status --short --branch
rtk proxy systemctl list-unit-files --no-pager 'happily*' 'casamento*'
```

Uma listagem vazia não cria nem inicia serviços. Não invente o nome de uma
unit, UID ou caminho de credenciais a partir do nome do projeto.

## Antes de permitir comandos de produção

O gate de reativação precisa aprovar e validar:

1. Dependências corrigidas e bundle disponível para um usuário dedicado sem sudo.
2. Release publicado em `/srv`, root-owned, com estado gravável separado.
3. Banco/role próprios e credenciais próprias protegidas.
4. Unit revisada com User, Group, WorkingDirectory, EnvironmentFiles e isolamento.
5. Backup, rollback e validação funcional e de segurança da aplicação dormente.

Após isso, documente os valores reais neste arquivo e teste primeiro um runner
que imprime somente UID, Rails.env e Rails.root. O padrão é uma unit temporária
via `rtk proxy sudo -n systemd-run --uid=<usuario-da-app> ...`, na qual o
systemd lê os EnvironmentFiles e o Ruby roda como a aplicação, nunca como root.

Se o runtime conservar o prefixo de compilação RVM, reproduza seu bind somente
leitura junto de ProtectHome. Para comandos pontuais, `DISABLE_BOOTSNAP=1`
pode evitar o uso de caches de outra identidade; isso não substitui configurar
o release, gems, usuário e credenciais corretos.

A receita validada em outros projetos está nos respectivos
`docs/RAILS_VPS_COMMANDS.md`. Seus valores não são intercambiáveis.

## Limite desta documentação

Não foi iniciado Rails, instalado bundle, alterado banco, carregado secret ou
reativado serviço HappilyEverAfter. A autorização para um deploy IntegrarPlus
não autoriza reativar este projeto.

