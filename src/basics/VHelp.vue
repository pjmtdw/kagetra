<template>
  <div class="d-inline-block">
    <v-icon ref="help" name="question-circle"/>
    <b-tooltip :target="() => $refs.help" placement="bottom">
      <slot/>
    </b-tooltip>
  </div>
</template>
