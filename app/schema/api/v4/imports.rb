class Api::V4::Imports
  class << self
    def all_definitions
      {
        patient: patient,
        contact_point: contact_point,
        appointment: appointment,
        observation_blood_pressure: observation_blood_pressure,
        observation_blood_sugar: observation_blood_sugar,
        condition: condition,
        medication_request: medication_request
      }
    end

    def schema_with_definitions
      import_resource_list.merge(definitions: all_definitions)
    end

    def codeable_concept(system:, codes:, description:)
      {
        type: :object,
        properties: {
          system: {type: :string, enum: [system], nullable: false},
          code: {type: :string, enum: codes, nullable: false, description: description}
        },
        nullable: false,
        required: %w[system code]
      }
    end

    def value_quantity(system:, unit:, code:)
      {
        type: :object,
        properties: {
          value: {type: "number", nullable: false},
          unit: {type: :string, enum: [unit], nullable: false},
          system: {type: :string, enum: [system], nullable: false},
          code: {type: :string, enum: [code], nullable: false}
        },
        nullable: false,
        required: %w[value unit system code]
      }
    end

    def resource_type(type)
      {type: :string, enum: [type], nullable: false}
    end

    def meta
      {
        type: :object,
        properties: {
          lastUpdated: Api::CommonDefinitions.timestamp,
          createdAt: Api::CommonDefinitions.timestamp
        },
        nullable: false,
        required: %w[lastUpdated createdAt]
      }
    end

    def identifier(description:)
      {
        type: :array,
        items: {
          type: :object,
          properties: {
            value: {type: :string, nullable: false, description: description}
          },
          required: ["value"]
        },
        nullable: false,
        minItems: 1,
        maxItems: 1
      }
    end

    def nullable_identifier(description:)
      identifier(description: description).merge!(type: [:array, :null], nullable: true, minItems: 0)
    end

    def reference(description:)
      {
        type: :object,
        properties: {
          identifier: {
            type: :string,
            nullable: false
          }
        },
        nullable: false,
        required: ["identifier"],
        description: description
      }
    end

    def nullable_reference(description:)
      reference(description: description).merge!(type: [:object, :null], nullable: true)
    end

    def contact_point
      {
        type: :object,
        properties: {
          value: {
            type: :string,
            nullable: false,
            description: "Phone number of the patient. Not having phone numbers will impact overdue reporting."
          },
          use: Api::CommonDefinitions.strict_enum(%w[home work temp old mobile]).merge!(
            description: 'Phone number type of the patient. \
                  Everything else other than "mobile" and "old", is marked as landline in Simple. \
                  "old" would mark the phone number as inactive.'
          )
        },
        required: ["value"]
      }
    end

    def address
      {type: :array,
       maxItems: 1,
       items: {
         type: [:object, :null],
         properties: {
           line: {
             type: [:null, :array],
             maxItems: 1,
             items: {type: :string,
                     description: "street address"}
           },
           city: {type: [:string, :null],
                  description: "village or colony"},
           district: {type: [:string, "null"]},
           state: {type: [:string, :null]},
           postalCode: {type: [:string, :null],
                        description: "pin"}
         }
       }}
    end

    def patient
      {
        type: :object,
        properties: {
          resourceType: resource_type("Patient"),
          meta: meta,
          identifier: identifier(description: "ID of the patient in the partner org database"),
          active: {
            type: "boolean",
            description: "Status of the patient. Will be ignored and marked as dead if deceasedBoolean is true",
            default: true
          },
          name: {
            type: [:object, :null],
            properties: {
              text: {
                type: [:string, :null]
              }
            },
            description: "Full name of the patient. Client can send anonymised names. \
                          If name is unset, Simple will generate a random name.",
            required: ["text"]
          },
          telecom: Api::CommonDefinitions.array_of("contact_point"),
          gender: Api::CommonDefinitions.strict_enum(%w[male female other])
            .merge!(description: "FHIR does not have a code for transgender, but Simple does.\
                    To accomodate this use case, we are considering 'other' to mean transgender."),
          birthDate: {
            type: :string,
            format: "date",
            description: "Date of birth. Can be an approximation."
          },
          deceasedBoolean: {
            type: [:boolean, :null]
          },
          managingOrganization: identifier(description: "Currently assigned facility ID"),
          registrationOrganization: nullable_identifier(description: "Registration facility ID"),
          address: address
        },
        required: %w[resourceType meta identifier gender birthDate managingOrganization]
      }
    end

    def appointment
      {
        type: :object,
        properties: {
          resourceType: resource_type("Appointment"),
          meta: meta,
          identifier: identifier(description: "ID of the appointment in the partner org database"),
          status: Api::CommonDefinitions.strict_enum(%w[pending fulfilled cancelled]).merge!({
            description: <<~DESCRIPTION
              Status of appointment. Translation to simple statuses:
              - pending: scheduled
              - fulfilled: visited
              - cancelled: cancelled
              This is a subset of all valid status codes in the FHIR standard.
            DESCRIPTION
          }),
          start: {type: [:string, :null],
                  format: "date-time",
                  nullable: false,
                  description: "Start datetime of appointment. Simple will truncate it to a date granularity."},
          participant: {
            type: "array",
            items: {type: :object,
                    properties: {
                      actor: reference(description: "ID of patient")
                    },
                    nullable: false,
                    required: ["actor"]},
            minItems: 1, maxItems: 1, nullable: false
          },
          appointmentOrganization: reference(
            description: "The reference to a facility in which the appointment is taking place. Modification to FHIR"
          ),
          appointmentCreationOrganization: nullable_reference(
            description: "The reference to a facility in which the appointment was created. Modification to FHIR"
          )
        },
        required: %w[resourceType meta identifier participant status appointmentOrganization]
      }
    end

    def observation_blood_pressure
      {
        type: :object,
        properties: {
          resourceType: resource_type("Observation"),
          meta: meta,
          identifier: identifier(description: "ID of the Blood Pressure in the partner org database"),
          subject: reference(description: "Patient ID"),
          performer: {type: "array",
                      items: reference(description: "Facility ID"),
                      nullable: false, minItems: 1, maxItems: 1},
          code: {
            type: :object,
            properties: {
              coding: {type: :array,
                       items: codeable_concept(
                         system: "http://loinc.org",
                         codes: ["85354-9"],
                         description: "Code for Blood Pressure panel"
                       ),
                       nullable: false, minItems: 1, maxItems: 1}
            },
            nullable: false,
            required: ["coding"]
          },
          component: {
            type: "array",
            items: {
              type: :object,
              properties: {
                code: {type: :object,
                       properties: {
                         coding: {type: "array",
                                  items: codeable_concept(
                                    system: "http://loinc.org",
                                    codes: %w[8480-6 8462-4],
                                    description: "8480-6 for Systolic, 8462-4 for Diastolic"
                                  ),
                                  nullable: false, minItems: 1, maxItems: 1}
                       },
                       nullable: false,
                       required: ["coding"]},
                valueQuantity: value_quantity(
                  system: "http://unitsofmeasure.org",
                  unit: "mmHg",
                  code: "mm[Hg]"
                )
              },
              required: %w[code valueQuantity],
              nullable: false, minItems: 2, maxItems: 2
            }
          },
          effectiveDateTime: Api::CommonDefinitions.timestamp.merge!({
            description: "When was this observation recorded?",
            nullable: false
          })
        },
        required: %w[resourceType meta identifier subject performer code component effectiveDateTime]
      }
    end

    def observation_blood_sugar
      {
        type: :object,
        properties: {
          resourceType: resource_type("Observation"),
          meta: meta,
          identifier: identifier(description: "ID of the Blood Sugar in the partner org database"),
          subject: reference(description: "Patient ID"),
          performer: {type: "array",
                      items: reference(description: "Facility ID"),
                      nullable: false, minItems: 1, maxItems: 1},
          code: {
            type: :object,
            properties: {
              coding: {type: :array,
                       items: codeable_concept(
                         system: "http://loinc.org",
                         codes: ["2339-0"],
                         description: "Code for Glucose [Mass/volume] in Blood"
                       ),
                       nullable: false, minItems: 1, maxItems: 1}
            },
            nullable: false,
            required: ["coding"]
          },
          component: {
            type: "array",
            items: {
              type: :object,
              properties: {
                code: {type: :object,
                       properties: {
                         coding: {type: "array",
                                  items: codeable_concept(
                                    system: "http://loinc.org",
                                    codes: %w[2339-0 87422-2 88365-24548-4],
                                    description: "2339-0 for random, \
                                                  87422-2 for post-prandial, \
                                                  88365-2 for fasting, \
                                                  4548-4 for hba1c"
                                  ),
                                  nullable: false, minItems: 1, maxItems: 1}
                       },
                       nullable: false,
                       required: ["coding"]},
                valueQuantity: {
                  oneOf: [
                    value_quantity(
                      system: "http://unitsofmeasure.org",
                      unit: "mg/dL",
                      code: "mg/dL"
                    ).merge!(description: "Unit for random, post-prandial and fasting"),
                    value_quantity(
                      system: "http://unitsofmeasure.org",
                      unit: "%",
                      code: "%"
                    ).merge!(description: "Unit for hba1c")
                  ]
                }
              },
              required: %w[code valueQuantity],
              nullable: false, minItems: 1, maxItems: 1
            }
          },
          effectiveDateTime: Api::CommonDefinitions.timestamp.merge!({
            description: "When was this observation recorded?",
            nullable: false
          })
        },
        required: %w[resourceType meta identifier subject performer code component effectiveDateTime]
      }
    end

    def condition
      {type: :object,
       properties: {
         resourceType: resource_type("Condition"),
         meta: meta,
         subject: identifier(description: "Patient ID"),
         code: {
           type: :object,
           properties: {
             coding: {
               type: "array",
               items: {
                 type: :object,
                 properties: {
                   system: {type: :string,
                            enum: ["http://snomed.info/sct"],
                            nullable: false},
                   code: {
                     # TODO: make this an enum
                     oneOf: [
                       {type: :string,
                        enum: ["38341003"],
                        description: "Code for HTN",
                        nullable: false},
                       {type: :string,
                        enum: ["73211009"],
                        description: "Code for diabetes",
                        nullable: false}
                     ]
                   }
                 },
                 required: %w[system code]
               },
               nullable: false,
               minItems: 1,
               maxItems: 2
             }
           },
           nullable: false,
           required: ["coding"]
         }
       },
       required: %w[resourceType meta subject code]}
    end

    def medication
      {
        type: :object,
        properties: {
          resourceType: resource_type("Medication"),
          id: {type: :string, nullable: false},
          code: {
            type: :object,
            properties: {
              coding: {
                type: "array",
                items: {type: :object,
                        properties: {
                          system: {type: :string,
                                   enum: ["http://www.nlm.nih.gov/research/umls/rxnorm"]},
                          code: {type: :string},
                          display: {type: :string, description: "Name of medicine"}
                        }},
                nullable: false,
                minItems: 1,
                maxItems: 1
              }
            },
            nullable: false,
            required: ["coding"]
          }
        },
        nullable: false,
        required: %w[resourceType id code]
      }
    end

    def medication_request
      {type: :object,
       properties: {
         contained: {type: "array",
                     items: medication,
                     nullable: false,
                     minItems: 1, maxItems: 1},
         resourceType: resource_type("MedicationRequest"),
         meta: meta,
         identifier: identifier(description: "ID of medication request"),
         subject: identifier(description: "Patient ID"),
         performer: identifier(description: "Facility ID"),
         medicationReference: {
           type: :object,
           properties: {reference: {type: :string, pattern: "^#.*$", nullable: false}},
           required: ["reference"],
           description: "This should reference the ID of contained medication resource"
         },
         dispenseRequest: {
           type: [:object, :null],
           properties: {
             expectedSupplyDuration: value_quantity(
               system: "http://unitsofmeasure.org",
               unit: "days",
               code: "d"
             ).merge!(type: [:object, :null], nullable: true)
           }
         },
         dosageInstruction: {
           type: :object,
           properties: {
             timing: {type: :object,
                      properties: {
                        code: {type: :string,
                               enum: %w[QD BID TID QID],
                               nullable: false,
                               description: "Mapping to Simple representation\n" \
                                 "QD: OD (Once a day)\n" \
                                 "BID: BD (Twice a day)\n" \
                                 "TID: TDS (Thrice a day)\n" \
                                 "QID: QDS (Four times a day)"}
                      }},
             doseAndRate: {type: "array",
                           items: {type: :object,
                                   properties: {
                                     doseQuantity: value_quantity(
                                       system: "http://unitsofmeasure.org",
                                       unit: "mg",
                                       code: "mg"
                                     )
                                   }},
                           description: "Dosage in milligrams"},
             text: {type: :string,
                    description: "Use only if dosage cannot be expressed in terms of the other fields."}
           }
         }
       },
       required: %w[resourceType meta identifier contained medicationReference subject performer]}
    end

    def import_request_payload
      {
        type: :object,
        properties: {
          resources: import_resource_list
        }
      }
    end

    def import_resource_list
      {
        type: :array,
        items: {
          oneOf: %w[
            patient
            appointment
            observation_blood_pressure
            observation_blood_sugar
            condition
            medication_request
          ].map { |resource| {"$ref" => "#/definitions/#{resource}"} }
        }
      }
    end
  end
end
