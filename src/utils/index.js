import Vue from 'vue';
import { now, isDate } from 'lodash';
import store from '@/store';

export { default as initDialogs } from './Dialogs';
export { calcTextareaHeight } from './calcHeight';
export { default as DialogMixin } from './DialogMixin';

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

export function escapeHtml(str) {
  if (!str) return str;
  return str.replace(/&/g, '&amp;')
    .replace(/>/g, '&gt;')
    .replace(/</g, '&lt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#x27;')
    .replace(/`/g, '&#x60;');
}

function parseDate(str) {
  const r = str.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (r === null) return null;
  return new Date(Number(r[1]), Number(r[2]) - 1, Number(r[3]));
}
// Date->曜日(String)
export function getWeekDay(arg) {
  let date = arg;
  if (typeof arg === 'string') {
    date = parseDate(arg);
  }
  if (!isDate(date)) {
    return null;
  }
  return '日月火水木金土'[date.getDay()];
}

export function timeRange(_start, _end, emphStart = false, emphEnd = false) {
  let start = escapeHtml(_start);
  let end = escapeHtml(_end);
  if (start && emphStart) start = `<strong><u>${start}</u></strong>`;
  if (end && emphEnd) end = `<strong><u>${end}</u></strong>`;
  if (start && end) {
    return `${start}&sim;${end}`;
  }
  if (start) {
    return `${start}&sim;`;
  }
  if (end) {
    return `&sim;${end}`;
  }
  return '';
}

export const env = {
  os: {},
  render: {
    webkit: navigator.userAgent.indexOf('WebKit') !== -1,
  },
  rem() {
    return parseFloat(getComputedStyle(document.documentElement).fontSize);
  },
};

export function createVueInstance(comp) {
  return new Vue({
    ...comp,
    store,
  });
}
