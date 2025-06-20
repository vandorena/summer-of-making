class Avo::Resources::ShipEventFeedback < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :ship_event, as: :belongs_to
    field :comment, as: :text
  end
end
