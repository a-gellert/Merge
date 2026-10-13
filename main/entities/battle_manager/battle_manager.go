components {
  id: "battle_manager"
  component: "/main/entities/battle_manager/battle_manager.script"
}
embedded_components {
  id: "bunch_factory"
  type: "factory"
  data: "prototype: \"/main/entities/bunch_controller/bunch_controller.go\"\n"
  ""
}
embedded_components {
  id: "cell_factory"
  type: "factory"
  data: "prototype: \"/main/entities/grid_cell/grid_cell.go\"\n"
  ""
}
embedded_components {
  id: "board_bg"
  type: "sprite"
  data: "default_animation: \"pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    y: 300.0
    z: -0.4
  }
  scale {
    x: 420.0
    y: 620.0
  }
}
embedded_components {
  id: "enemy_mat_fill"
  type: "sprite"
  data: "default_animation: \"pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: 200.0
    y: 1534.0
    z: -0.32
  }
  scale {
    x: 800.0
    y: 600.0
  }
}
embedded_components {
  id: "enemy_mat"
  type: "sprite"
  data: "default_animation: \"rect_round2_width2\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: 200.0
    y: 519.0
    z: -0.3
  }
  scale {
    x: 5.6
    y: 5.6
  }
}
embedded_components {
  id: "player_mat_fill"
  type: "sprite"
  data: "default_animation: \"pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: 200.0
    y: -874.0
    z: -0.32
  }
  scale {
    x: 800.0
    y: 600.0
  }
}
embedded_components {
  id: "player_mat"
  type: "sprite"
  data: "default_animation: \"rect_round2_width2\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: 200.0
    y: 220.0
    z: -0.3
  }
  scale {
    x: 8.0
    y: 8.0
  }
}
embedded_components {
  id: "midline"
  type: "sprite"
  data: "default_animation: \"pixel\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/druid/druid.atlas\"\n"
  "}\n"
  ""
  position {
    x: 200.0
    y: 330.0
    z: -0.25
  }
  scale {
    x: 800.0
    y: 2.0
  }
}
