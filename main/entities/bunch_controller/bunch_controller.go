components {
  id: "bunch_controller"
  component: "/main/entities/bunch_controller/bunch_controller.script"
}
embedded_components {
  id: "melee_factory"
  type: "factory"
  data: "prototype: \"/main/entities/melee/melee.go\"\n"
  ""
}
embedded_components {
  id: "archer_factory"
  type: "factory"
  data: "prototype: \"/main/entities/archer/archer.go\"\n"
  ""
}
embedded_components {
  id: "shadow"
  type: "sprite"
  data: "default_animation: \"squad_glow\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    x: 0
    y: -3
    z: -0.06
  }
  scale {
    x: 0.95
    y: 0.75
  }
}
embedded_components {
  id: "base_ring"
  type: "sprite"
  data: "default_animation: \"squad_ring\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    x: 0
    y: 0
    z: -0.05
  }
  scale {
    x: 0.92
    y: 0.92
  }
}
embedded_components {
  id: "buff_ring"
  type: "sprite"
  data: "default_animation: \"fx_ring\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    x: 0
    y: 0
    z: 0.12
  }
  scale {
    x: 1.1
    y: 1.1
  }
}
embedded_components {
  id: "crown"
  type: "sprite"
  data: "default_animation: \"icon_crown\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    x: 24
    y: 20
    z: 0.3
  }
  scale {
    x: 0.17
    y: 0.17
  }
}
embedded_components {
  id: "badge"
  type: "sprite"
  data: "default_animation: \"tier_badge\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    x: 0
    y: -27
    z: 0.2
  }
  scale {
    x: 0.31
    y: 0.31
  }
}
embedded_components {
  id: "tier_label"
  type: "label"
  data: "size {\n"
  "  x: 48.0\n"
  "  y: 32.0\n"
  "}\n"
  "color {\n"
  "  x: 0.09\n"
  "  y: 0.1\n"
  "  z: 0.16\n"
  "}\n"
  "outline {\n"
  "  x: 0.09\n"
  "  y: 0.1\n"
  "  z: 0.16\n"
  "}\n"
  "text: \"1\"\n"
  "font: \"/druid/fonts/druid_text_bold.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  position {
    x: 0
    y: -27
    z: 0.25
  }
  scale {
    x: 0.36
    y: 0.36
  }
}
embedded_components {
  id: "badge_e"
  type: "sprite"
  data: "default_animation: \"tier_badge\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/game.atlas\"\n"
  "}\n"
  ""
  position {
    x: 0
    y: 27
    z: 0.2
  }
  scale {
    x: 0.31
    y: 0.31
  }
}
embedded_components {
  id: "tier_label_e"
  type: "label"
  data: "size {\n"
  "  x: 48.0\n"
  "  y: 32.0\n"
  "}\n"
  "color {\n"
  "  x: 0.09\n"
  "  y: 0.1\n"
  "  z: 0.16\n"
  "}\n"
  "outline {\n"
  "  x: 0.09\n"
  "  y: 0.1\n"
  "  z: 0.16\n"
  "}\n"
  "text: \"1\"\n"
  "font: \"/druid/fonts/druid_text_bold.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  position {
    x: 0
    y: 27
    z: 0.25
  }
  scale {
    x: 0.36
    y: 0.36
  }
}
