export { default as initNotifications } from './Notifications';
export { default as FormItemMixin } from './FormItemMixin';
export { calcTextareaHeight, calcElementHeight } from './calcHeight';

const beforeUnloads = {};
export function setBeforeUnload(name, isChanged) {
  beforeUnloads[name] = (e) => {
    if (isChanged()) {
      e.returnValue = '';
      return '';
    }
    return undefined;
  };
  window.addEventListener('beforeunload', beforeUnloads[name]);
}
export function unsetBeforeUnload(name) {
  window.removeEventListener('beforeunload', beforeUnloads[name]);
}
