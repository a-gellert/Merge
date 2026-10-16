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
  id: "base_ring"
  type: "sprite"
  data: "default_animation: \"ui_circle_32\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    z: -0.05
  }
  scale {
    x: 1.15
    y: 1.15
  }
}
embedded_components {
  id: "buff_ring"
  type: "sprite"
  data: "default_animation: \"ui_circle_32\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.12
  }
  scale {
    x: 1.38
    y: 1.38
  }
}
embedded_components {
  id: "tier_label"
  type: "label"
  data: "size {\n"
  "  x: 32.0\n"
  "  y: 32.0\n"
  "}\n"
  "color {\n"
  "  x: 0.8\n"
  "  y: 0.8\n"
  "  z: 0.2\n"
  "}\n"
  "text: \"1\"\n"
  "font: \"/druid/fonts/druid_text_bold.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  position {
    y: -31.0
    z: 0.2
  }
  scale {
    x: 0.55
    y: 0.55
  }
}
