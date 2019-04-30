import { now } from 'lodash';

export { default as initNotifications } from './Notifications';
export { calcTextareaHeight } from './calcHeight';

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

export function waitUntil(check, timeout) {
  const end = now() + timeout;
  const exec = (resolve, reject) => {
    if (check()) resolve();
    else if (now() > end) reject();
    else setTimeout(exec, 50, resolve, reject);
  };
  return new Promise(exec);
}
