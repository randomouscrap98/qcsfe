export const replaceAttribute = "t-replace";
export const fillAttribute = "t-fill";
export const templateId = "templates";

export function getTemplatesElement()
{
   return document.getElementById(templateId);
}

export function cloneTemplate(name) 
{
   var template = getTemplatesElement().content.getElementById(name).cloneNode(true);
   template.removeAttribute("id");
   template.setAttribute("data-template", name);
   return template;
}

export function composeTemplates()
{
   var templates = getTemplatesElement();

   while(true)
   {
      var replaceElements = [...templates.content.querySelectorAll(`[${replaceAttribute}]`)];
      var fillElements = [...templates.content.querySelectorAll(`[${fillAttribute}]`)];

      if(replaceElements.length === 0 && fillElements.length === 0) 
         break;

      replaceElements.forEach(x => {
         var replacement = cloneTemplate(x.getAttribute(replaceAttribute));
         x.parentNode.replaceChild(replacement, x);
      });

      fillElements.forEach(x => {
         var filler = cloneTemplate(x.getAttribute(fillAttribute));
         if(x.tagName === "TEMPLATE")
            x.content.appendChild(filler);
         else
            x.appendChild(filler);
         x.removeAttribute(fillAttribute);
      });

   }
};
