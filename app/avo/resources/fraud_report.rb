class Avo::Resources::FraudReport < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :reporter, as: :belongs_to
    field :suspect_type, as: :text
    field :suspect_id, as: :text
    field :reason, as: :text
  end
end
