import { defineStore } from 'pinia';
import { ref } from 'vue';

export const useHudStore = defineStore('hud', () => {
    const health = ref(100);
    const shield = ref(100);
    const hunger = ref(100);
    const thirst = ref(100);

    function updateStatus(data) {
        health.value = data.health ?? 100;
        shield.value = data.shield ?? 100;
        hunger.value = data.hunger ?? 100;
        thirst.value = data.thirst ?? 100;
    }

    return {
        health,
        shield,
        hunger,
        thirst,
        updateStatus
    };
});
