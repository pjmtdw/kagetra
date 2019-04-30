const sm = 576;
const md = 768;
const lg = 992;
const xl = 1200;
const devices = {
  xs: 0,
  sm: 1,
  md: 2,
  lg: 3,
  xl: 4,
};

const calcScreenSize = () => {
  const w = window.innerWidth;
  if (w >= xl) return 'xl';
  if (w >= lg) return 'lg';
  if (w >= md) return 'md';
  if (w >= sm) return 'sm';
  return 'xs';
};

export default {
  namespaced: true,
  state: {
    screen: calcScreenSize(),
  },
  getters: {
    from(state) {
      return device => devices[state.screen] >= devices[device];
    },
    until(state) {
      return device => devices[state.screen] <= devices[device];
    },
  },
  mutations: {
    resize(state) {
      state.screen = calcScreenSize();
    },
  },
};