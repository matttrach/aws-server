
output "servers" {
  value = merge(
  { 
    "${local.names[0]}" = module.initial_server.private_ip
  },
  {
    for name in slice(local.names,1,length(local.names)): name => module.subsequent_servers[name].private_ip
  },
  )
}

output "bastion" {
  value = module.bastion_server.public_ip
}
