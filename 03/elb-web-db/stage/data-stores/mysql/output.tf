output "addr" {
    value = aws_db_instance.myDBinstance.address
    description = "db-addr"
}

output "port" {
    value = aws_db_instance.myDBinstance.port
    description = "db-port"
}

