# Workshop in [${location}]

%{ for vm in vms ~}
- ${vm.name}: ${vm.public_ip} (user: ${vm.username} / password: ${vm.password})
%{ endfor ~}
