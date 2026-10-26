components {
  id: "projectile"
  component: "/main/entities/projectile/projectile.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"arrow\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    x: 0
    y: 0
    z: 0
  }
  scale {
    x: 0.55
    y: 0.55
  }
}
