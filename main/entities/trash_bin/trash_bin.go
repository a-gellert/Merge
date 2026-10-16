components {
  id: "trash_bin"
  component: "/main/entities/trash_bin/trash_bin.script"
}
embedded_components {
  id: "bg_glow"
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
    x: 3.2
    y: 1.4
  }
}
embedded_components {
  id: "plate"
  type: "sprite"
  data: "default_animation: \"rect_round2_width2\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 3.6
    y: 1.25
  }
}
embedded_components {
  id: "plate_fill"
  type: "sprite"
  data: "default_animation: \"pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.01
  }
  scale {
    x: 64.0
    y: 16.0
  }
}
embedded_components {
  id: "can_body"
  type: "sprite"
  data: "default_animation: \"rect_round2_width2\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: -22.0
    y: -2.0
    z: 0.05
  }
  scale {
    x: 0.65
    y: 0.72
  }
}
embedded_components {
  id: "can_lid"
  type: "sprite"
  data: "default_animation: \"rect_round2_width2\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: -22.0
    y: 6.0
    z: 0.06
  }
  scale {
    x: 0.85
    y: 0.22
  }
}
embedded_components {
  id: "can_handle"
  type: "sprite"
  data: "default_animation: \"rect_round2_width1\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: -22.0
    y: 9.0
    z: 0.07
  }
  scale {
    x: 0.35
    y: 0.14
  }
}
embedded_components {
  id: "coin_icon"
  type: "sprite"
  data: "default_animation: \"ui_circle_16\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: 2.0
    z: 0.05
  }
  scale {
    x: 0.8
    y: 0.8
  }
}
embedded_components {
  id: "price_label"
  type: "label"
  data: "size {\n"
  "  x: 50.0\n"
  "  y: 30.0\n"
  "}\n"
  "color {\n"
  "  y: 0.92\n"
  "  z: 0.3\n"
  "}\n"
  "text: \"+10\"\n"
  "font: \"/druid/fonts/druid_text_bold.font\"\n"
  "material: \"/builtins/fonts/label-df.material\"\n"
  ""
  position {
    x: 22.0
    z: 0.06
  }
  scale {
    x: 0.48
    y: 0.48
  }
}
