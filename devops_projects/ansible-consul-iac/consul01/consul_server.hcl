# Конфигурация сервера Consul.
#
# bootstrap_expect = 1 — кластер считается собранным при одном сервере.
# Для стенда этого достаточно; в рабочем окружении серверов берут три
# или пять, чтобы кворум переживал отказ узла.
#
# bind_addr и advertise_addr различаются намеренно. Первый говорит, на каких
# интерфейсах слушать (на всех), второй — какой адрес сообщать соседям.
# У машины Vagrant два интерфейса, и без явного advertise_addr Consul может
# объявить NAT-овский адрес, по которому клиенты до него не достучатся.
#
# client_addr = "0.0.0.0" открывает HTTP API и веб-интерфейс наружу —
# допустимо для локального стенда и недопустимо в рабочем окружении.
#
# connect { enabled = true } включает service mesh: сервисы получают
# sidecar-прокси и обращаются друг к другу через них, а не напрямую.

datacenter = "dc1"
node_name = "consul-server"
data_dir = "/opt/consul/data"

bind_addr = "0.0.0.0"
advertise_addr = "192.168.56.20"

server = true
bootstrap_expect = 1

client_addr = "0.0.0.0"
ui_config { enabled = true }

connect { enabled = true }
ports { grpc = 8502 }