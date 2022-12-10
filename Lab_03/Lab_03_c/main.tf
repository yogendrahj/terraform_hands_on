module "test_module" {
  source = "./module"
  environment = "DEV"
}

output "yogi_terraform_user" {
  value = module.test_module.yogi_terraform_output
}