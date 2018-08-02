class AddDocumentRefToPoints < ActiveRecord::Migration[5.1]
  def change
    add_reference :points, :document, foreign_key: true

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE points AS p
          SET document_id = d.id
          FROM documents AS d
          WHERE p.service_id = d.service_id AND p."quoteDoc" = d.name AND p."quoteText" IS NOT NULL
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE points AS p
          SET "quoteDoc" = d.name, "quoteRev" = 'latest'
          FROM documents AS d
          WHERE p.service_id = d.service_id AND p.document_id = d.id AND p."quoteText" IS NOT NULL
        SQL
      end
    end

    remove_column :points, :quoteDoc, :string
    remove_column :points, :quoteRev, :string
  end
end
