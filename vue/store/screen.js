const gap = 32;
const tablet = 769;
const desktop = 960 + 2 * gap;
const widescreen = 1152 + 2 * gap;
const fullhd = 1344 + 2 * gap;
const devices = {
  mobile: 0,
  tablet: 1,
  desktop: 2,
  widescreen: 3,
  fullhd: 4,
};

const calcScreenSize = () => {
  const h = window.innerWidth;
  // console.log('called', h);
  if (h < tablet) return 'mobile';
  if (h < desktop) return 'tablet';
  if (h < widescreen) return 'desktop';
  if (h < fullhd) return 'desktop';
  return 'fullhd';
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
