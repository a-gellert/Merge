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
  id: "effect_factory"
  type: "factory"
  data: "prototype: \"/main/entities/visual_effect/visual_effect.go\"\n"
  ""
}
embedded_components {
  id: "card_factory"
  type: "factory"
  data: "prototype: \"/main/entities/card/card.go\"\n"
  ""
}
embedded_components {
  id: "crate_factory"
  type: "factory"
  data: "prototype: \"/main/entities/crate/crate.go\"\n"
  ""
}
embedded_components {
  id: "board_bg"
  type: "sprite"
  data: "default_animation: \"arena_bg\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/assets/background.atlas\"\n"
  "}\n"
  ""
  position {
    x: 200.0
    y: 320.5
    z: -0.45
  }
  scale {
    x: 0.5
    y: 0.5
  }
}
