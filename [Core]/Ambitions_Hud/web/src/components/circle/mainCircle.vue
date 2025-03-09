<script setup>
import healthIcon from '@/assets/icons/heart.svg';
import shieldIcon from '@/assets/icons/shield.svg';
import foodIcon from '@/assets/icons/food.svg';
import waterIcon from '@/assets/icons/water.svg';
import { ref, onMounted, computed } from 'vue';
import { useHudStore } from '@/stores/hud';

const store = useHudStore();

// On fixe la taille du cercle en pixels
const circleSize = ref(70);

const circleStyle = computed(() => ({
  width: circleSize.value + 'px',
  height: circleSize.value + 'px'
}));

onMounted(() => {
  window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.action === 'updateStatus') {
      store.updateStatus(data);
    }
  });
});
</script>

<template>
  <div class="circles-container">
    <!-- Cercle de vie -->
    <div class="circle-container" :style="circleStyle">
      <v-progress-circular
        :size="circleSize"
        :width="5"
        :value="store.health"
        color="#4caf50"
        rotate="-90"
      >
        <div class="circle">
          <span class="icon">
            <img :src="healthIcon" alt="Health Icon" class="icon-svg" />
          </span>
          <span class="circle-value">{{ Math.floor(store.health) }}%</span>
        </div>
      </v-progress-circular>
    </div>

    <!-- Cercle de bouclier -->
    <div class="circle-container" :style="circleStyle">
      <v-progress-circular
        :size="circleSize"
        :width="5"
        :value="store.shield"
        color="#42a5f5"
        rotate="-90"
      >
        <div class="circle">
          <span class="icon">
            <img :src="shieldIcon" alt="Shield Icon" class="icon-svg" />
          </span>
          <span class="circle-value">{{ Math.floor(store.shield) }}%</span>
        </div>
      </v-progress-circular>
    </div>

    <!-- Cercle de faim -->
    <div class="circle-container" :style="circleStyle">
      <v-progress-circular
        :size="circleSize"
        :width="5"
        :value="store.hunger"
        color="#ff9800"
        rotate="-90"
      >
        <div class="circle">
          <span class="icon">
            <img :src="foodIcon" alt="Food Icon" class="icon-svg" />
          </span>
          <span class="circle-value">{{ Math.floor(store.hunger) }}%</span>
        </div>
      </v-progress-circular>
    </div>

    <!-- Cercle de soif -->
    <div class="circle-container" :style="circleStyle">
      <v-progress-circular
        :size="circleSize"
        :width="5"
        :value="store.thirst"
        color="#1565c0"
        rotate="-90"
      >
        <div class="circle">
          <span class="icon">
            <img :src="waterIcon" alt="Water Icon" class="icon-svg" />
          </span>
          <span class="circle-value">{{ Math.floor(store.thirst) }}%</span>
        </div>
      </v-progress-circular>
    </div>
  </div>
</template>

<style scoped>
.circles-container {
  position: fixed;
  bottom: 5vh;
  left: 5vw;
  display: flex;
  gap: 20px;
  align-items: center;
  justify-content: center;
}

.circle-container {
  /* Le style (largeur/hauteur) est défini via circleStyle */
  position: relative;
}

.circle {
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.3);
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
}

.icon-svg {
  width: 55%;
  height: 55%;
}

.circle-value {
  position: absolute;
  bottom: -12px;
  color: white;
  font-size: 12px;
  text-shadow: 1px 1px 2px black;
}
</style>
