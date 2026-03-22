import type { SwipeAnimPhaseEntry, SwipeTxEntry } from '../model/IndexTypes';

export function swipeRowKeyFolder(folder: string): string {
  return `F:${folder}`;
}

export function swipeRowKeyBookmark(folder: string, url: string): string {
  return `B:${folder}\t${url}`;
}

export function getSwipeTranslateX(entries: Array<SwipeTxEntry>, key: string): number {
  let i: number = 0;
  while (i < entries.length) {
    if (entries[i].key === key) {
      return entries[i].x;
    }
    i++;
  }
  return 0;
}

export function upsertSwipeTranslate(entries: Array<SwipeTxEntry>, key: string, x: number): Array<SwipeTxEntry> {
  const out: Array<SwipeTxEntry> = [];
  let found: boolean = false;
  let j: number = 0;
  while (j < entries.length) {
    const e: SwipeTxEntry = entries[j];
    if (e.key === key) {
      out.push({ key: key, x: x });
      found = true;
    } else {
      out.push(e);
    }
    j++;
  }
  if (!found) {
    out.push({ key: key, x: x });
  }
  return out;
}

export function removeSwipeTranslate(entries: Array<SwipeTxEntry>, key: string): Array<SwipeTxEntry> {
  const out: Array<SwipeTxEntry> = [];
  let i: number = 0;
  while (i < entries.length) {
    if (entries[i].key !== key) {
      out.push(entries[i]);
    }
    i++;
  }
  return out;
}

export function getSwipeAnimPhase(entries: Array<SwipeAnimPhaseEntry>, key: string): number {
  let i: number = 0;
  while (i < entries.length) {
    if (entries[i].key === key) {
      return entries[i].phase;
    }
    i++;
  }
  return 0;
}

export function upsertSwipeAnimPhase(
  entries: Array<SwipeAnimPhaseEntry>,
  key: string,
  phase: number
): Array<SwipeAnimPhaseEntry> {
  const out: Array<SwipeAnimPhaseEntry> = [];
  let found: boolean = false;
  let j: number = 0;
  while (j < entries.length) {
    const e: SwipeAnimPhaseEntry = entries[j];
    if (e.key === key) {
      out.push({ key: key, phase: phase });
      found = true;
    } else {
      out.push(e);
    }
    j++;
  }
  if (!found) {
    out.push({ key: key, phase: phase });
  }
  return out;
}

export function removeSwipeAnimPhase(entries: Array<SwipeAnimPhaseEntry>, key: string): Array<SwipeAnimPhaseEntry> {
  const out: Array<SwipeAnimPhaseEntry> = [];
  let i: number = 0;
  while (i < entries.length) {
    if (entries[i].key !== key) {
      out.push(entries[i]);
    }
    i++;
  }
  return out;
}
