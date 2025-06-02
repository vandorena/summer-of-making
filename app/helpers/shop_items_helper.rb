module ShopItemsHelper

  # <%= text_field_editable(@item, :name) %>
  def text_field_editable(item, field_name)
    container_id = "item-#{item.id}-container-#{field_name}"

    html = content_tag(:div, id: container_id, class: "item-container") do
      safe_join([
        content_tag(:div, class: "item", style: "display: flex;") do
          concat content_tag(:p, item.public_send(field_name))
          admin_tool do
            button_tag "Edit", class: "edit"
          end
        end,

        form_with(model: item, html: { style: "display: none;" }) do |f|
          safe_join([f.text_field(field_name), f.submit])
        end
      ])
    end

    js = javascript_tag <<~JS
      document.addEventListener("DOMContentLoaded", () => {
        const container = document.getElementById("#{container_id}");
        if (!container) return;

        const row  = container.querySelector(".item");
        const form = container.querySelector("form");

        container.querySelector("button.edit").onclick = () => {
          row.style.display  = "none";
          form.style.display = "block";
        };

        form.onsubmit = (e) => {
          e.preventDefault();
          const data = new FormData(form);

          fetch("#{url_for(item)}", {
            method: "PATCH",
            body: data,
            headers: {
              "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
              "Accept": "application/json"
            },
            credentials: "same-origin"
          }).then(() => window.location.reload());
        };
      });
    JS

    safe_join([html, js])
  end
end
