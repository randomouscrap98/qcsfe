import { cloneTemplate } from './lib/template-system.js';
import { UserView, MessageView } from './lib/views.js';

export default {
   main : () => ({
      newmake() {
         var container = this.$root.querySelector('[data-container]');
         var template = cloneTemplate("message");
         var msg = Math.random();
         template.setAttribute("x-data", `message(${msg})`);
         container.appendChild(template);
      }
   }),
   message_fragment : () => ({
      message : MessageView()
   }),
   message_block : () => ({
      get root_message () { this.messages[0] },
      messages : []
   })
};
