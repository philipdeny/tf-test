resource "null_resource" "dscript" {

  provisioner "local-exec" {

    command = "/bin/bash ./dscript.sh"
  }
}