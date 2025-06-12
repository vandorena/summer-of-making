class Avo::Resources::ShopOrder < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :shop_item, as: :belongs_to
    field :frozen_item_price, as: :text
    field :quantity, as: :number
    field :frozen_address, as: :code
    field :aasm_state, as: :text
  end
end
