components {
  id: "projectile_manager"
  component: "/main/entities/projectile_manager/projectile_manager.script"
}
embedded_components {
  id: "projectile_factory"
  type: "factory"
  data: "prototype: \"/main/entities/projectile/projectile.go\"\n"
  ""
}
