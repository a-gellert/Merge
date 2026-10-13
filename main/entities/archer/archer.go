components {
  id: "archer"
  component: "/main/entities/archer/archer.script"
}
embedded_components {
  id: "outline"
  type: "sprite"
  data: "default_animation: \"ui_circle_16\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.0
  }
  scale {
    x: 0.58
    y: 0.58
    z: 1.0
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"ui_circle_16\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    z: 0.02
  }
  scale {
    x: 0.46
    y: 0.46
    z: 1.0
  }
}
embedded_components {
  id: "arrow_crest"
  type: "sprite"
  data: "default_animation: \"icon_arrow\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: 0.0
    y: 4.8
    z: 0.03
  }
  rotation {
    z: 0.70710677
    w: 0.70710677
  }
  scale {
    x: 0.35
    y: 0.35
    z: 1.0
  }
}
embedded_components {
  id: "eye_l_white"
  type: "sprite"
  data: "default_animation: \"ui_circle_8\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: -1.8
    y: 1.0
    z: 0.04
  }
  scale {
    x: 0.28
    y: 0.28
    z: 1.0
  }
}
embedded_components {
  id: "eye_r_white"
  type: "sprite"
  data: "default_animation: \"ui_circle_8\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: 1.8
    y: 1.0
    z: 0.04
  }
  scale {
    x: 0.28
    y: 0.28
    z: 1.0
  }
}
embedded_components {
  id: "eye_l_pupil"
  type: "sprite"
  data: "default_animation: \"ui_circle_8\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: -1.8
    y: 1.7
    z: 0.06
  }
  scale {
    x: 0.14
    y: 0.14
    z: 1.0
  }
}
embedded_components {
  id: "eye_r_pupil"
  type: "sprite"
  data: "default_animation: \"ui_circle_8\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: 1.8
    y: 1.7
    z: 0.06
  }
  scale {
    x: 0.14
    y: 0.14
    z: 1.0
  }
}
