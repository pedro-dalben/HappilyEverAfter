# Comandos Rails na VPS — HappilyEverAfter

## Produção ativa

Desde 2026-09-19, a aplicação é atendida por
`happilyeverafter.service`, executada como `app-casamento`. O código publicado
fica em `/srv/casamento/current`; estado gravável fica em `/var/lib/casamento`;
as credenciais ficam no EnvironmentFile root-only `/etc/casamento/production.env`.
O Puma escuta somente em `127.0.0.1:3000` e o Nginx atende HTTPS.

Não execute Rails como root, nem reutilize usuário, release, banco ou
EnvironmentFile de outro projeto.

## Operação e verificação

```bash
sudo systemctl status happilyeverafter.service --no-pager
sudo systemctl restart happilyeverafter.service
sudo journalctl -u happilyeverafter.service -n 100 --no-pager
curl --noproxy '*' -fsS -o /dev/null -w '%{http_code}\n' \
  https://casamento.pedrodalben.com.br/
```

O serviço deve permanecer `active`, com o listener limitado a `127.0.0.1:3000`:

```bash
sudo ss -lntp '( sport = :3000 )'
```

Para uma publicação nova, passe pelo deploy que mantém o release root-owned,
o bundle no próprio release e os links para `log`, `storage` e `tmp` em
`/var/lib/casamento`. Valide o bundle e o boot na sandbox do systemd antes de
trocar o symlink `current` e recarregar o serviço.

## Recuperação

Antes da reativação foi criado backup PostgreSQL em
`/var/backups/casamento-reactivation-20260919`, acessível somente por root.
Em uma regressão, restaure em manutenção a partir desse backup ou alterne
`/srv/casamento/current` para um release previamente validado e reinicie a
unit. Não misture bancos entre aplicações.
