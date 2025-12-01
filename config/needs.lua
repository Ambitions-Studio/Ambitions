needsConfig = {
  defaults = {
    hunger = 100,
    thirst = 100
  },

  degradation = {
    hunger = {
      enabled = true,
      amount = 1,
      interval = 60000
    },
    thirst = {
      enabled = true,
      amount = 1,
      interval = 45000
    },
    healthDecay = {
      enabled = true,
      amount = 5,
      interval = 60000
    }
  },

  limits = {
    min = 0,
    max = 100
  }
}
