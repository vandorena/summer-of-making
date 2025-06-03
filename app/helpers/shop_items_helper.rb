module ShopItemsHelper
  def text_field_editable(item, field_name, display_prefix: "")
    editable(item, field_name, display_prefix, false)
  end

  def number_field_editable(item, field_name, display_prefix: "")
    editable(item, field_name, display_prefix, true)
  end

  private

  def editable(item, field_name, display_prefix = "", is_number)
    container_id = "item-#{item.id}-container-#{field_name}"

    style = "line-clamp-3 text-sm md:text-base 2xl:text-lg text-gray-600 break-words overflow-wrap-anywhere"
    if field_name == :name
      style = "text-2xl"
    end

    html = content_tag(:div, id: container_id, class: "item-container") do
      safe_join([
        content_tag(:div, class: "item", style: "display: flex;") do
          raw_value = item.public_send(field_name)
          value = is_number ? raw_value : raw_value
          concat content_tag(:p, "#{display_prefix}#{value}", class: style)
          admin_tool("m-0 px-1 py-0 ml-auto") do
            button_tag "Edit", class: "edit"
          end
        end,

        form_with(model: item, html: { style: "display: none;" }) do |f|
          form_field = is_number ? f.number_field(field_name, step: 0.01) : f.text_field(field_name)
          safe_join([ form_field, f.submit ])
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

    safe_join([ html, js ])
  end
end
