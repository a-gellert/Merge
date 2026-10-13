components {
  id: "grid_cell"
  component: "/main/entities/grid_cell/grid_cell.script"
}
embedded_components {
  id: "bg"
  type: "sprite"
  data: "default_animation: \"pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    z: -0.01
  }
  scale {
    x: 16.0
    y: 16.0
  }
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"rect_round2_width2\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  scale {
    x: 2.15
    y: 2.15
  }
}
