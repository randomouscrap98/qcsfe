/*
 * IDK if I'm doing this right, what with Alpine in here... alpine isn't a
 * module though so I can't just import it, and I can't find alpine as a module
 * version anywhere, so...
 */

import AlpineTemplates from './alpine-templates.js';
import { composeTemplates } from './lib/template-system.js';

document.addEventListener("alpine:init", () => {
   console.debug("ALPINE INIT");
   for(const [key, value] of Object.entries(AlpineTemplates))
   {
      Alpine.data(key, value);
   }
});

composeTemplates();

