components {
  id: "grid_cell"
  component: "/main/entities/grid_cell/grid_cell.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"cell\"\n"
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
    x: 0.84
    y: 0.84
  }
}
