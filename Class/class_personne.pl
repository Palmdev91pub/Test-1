/*******************************************************************************
* OWNERSHIP
*
* PROJECT
*
* AUTHORS     COSYTEC SA
*             Parc Club Orsay Universite
*             4, rue Jean Rostand
*             F-91893 Orsay Cedex, France
* TEL         +33 1 60 19 37 38
* FAX         +33 1 60 19 36 20
* EMAIL       cosytec@cosytec.fr
*
* FILE        %M%
* VERSION     %I%
* DATE        %G%
* COPYRIGHT   Copyright (c) 1994 COSYTEC SA
*******************************************************************************/
/*******************************************************************************
*
% personne(+Personne, aptitude(+/-TypeRessource, +/-DemandeRessource, +Date))
*        Verifie ou donne les type_ressources et demande_ressources d''une personne à une date J
*
% personne(+Personne, aptitude(+/-TypeRessource, +/-DemandeRessource, +Date_Debut, +Date_Fin))
*        Verifie ou donne les type_ressources et demande_ressources d''une personne qui CHEVAUCHE une période
*
% personne(Personne, is_in_equipe_principal(DateD, DateF))
*        Réussi si une personne appartient en principale à l''équipe chargée (par le micro-planif)
*
% personne(Personne, is_in_metier_principal(DateD, DateF))
*        Réussi si une personne appartient en principal au métier chargé (par le planif-ressource)
*
% personne(Name, get_equipe_cycle(Date, Appart, Equipe_cycle))
*        Renvoie l''équipe d''une personne à une date donnée
*
% personne(Personne, metier_principal(From, To, TypeRessource))
*        Récupere ou verifie le métier principal de la personne
*
* MSG DEDIES A LA GESTION DES PERSONNES CYCLIQUES
*
% personne(Name, get_canevas(Date, Canevas))
% personne(Name, get_canevas(Date, Canevas, Flag))
% personne(Name, get_equipe_canevas(Date, Appart, Equipe_cycle, Canevas))
% personne(Name, get_equipe_canevas(Date, Appart, Equipe_cycle, Canevas, Flag))
% personne(Name, get_equipe_canevas(Date, Appart, Equipe_cycle, Canevas, Roulement, Flag))
% personne(Name, get_equipe_canevas(Date, Appart, Equipe_cycle, Canevas, R, Flag, Ligne))
*        Renvoie l''équipe et le canevas auquel appartient la personne à une date donnée
*        Ainsi qu''un flag '0' ou '1' s''il y a rotation ou non
*
% personne(Name, get_periode_cycle(+Date, -From, -To))
*         Recupere la periode du cycle de la personne couvrant une date donnée
*
% personne(+Personne, get_planning(-PS))
% personne(+Personne, get_planning(-PS))
*        Récupère le planning d''une personne
*
% personne(+Personne, has_dispo(+Debut_W, +Fin_W, +Duration)):-
*        Regarde si la personne possède une dispo entre deux dates
*        Attention: Ne fonctionne pour le moment que pour le module Technicien 
% personne(+Personne, is_salarie_etranger)
*       réussit si la personne est un salarié étranger
*
% personne(+Personne, autorisation_de_travail(-From, -To))
*
*       retourne la période de validité de l''autorisation de travail pour un salarié étranger
*******************************************************************************/
?- util_declare(specific_personne_panel_manager_before_open(personne), fail).
?- util_declare(specific_personne_panel_manager_item_check_callback(_, _, _, _), fail).
?- util_declare(specific_personne(_, db_after_upload), fail).
?- util_declare(specific_personne(_, db_cond(Cond, Goal)), fail).
?- util_declare(specific_personne(preprocess), fail).
?- util_declare(specific_personne_panel_manager_before_fill(personne), fail).
?- util_declare(specific_personne_panel_manager_attribute_state(personne, Attr, Status), fail).
?- util_declare(specific_personne_check_can_modify(Name, Atts, Flag), true).
?- util_declare(specific_personne_key_callback(Name, Item, Type, Mode, Key), fail).
?- util_declare(specific_personne_check_db_before_upload, true).

?- util_declare(specific_personne_check_can_destroy(Name, can_destroy), true).

?- util_declare(specific_personne_panel_manager_closed(0, 0), fail).

?- util_declare(specific_personne_panel_manager_object_changed(personne, Name, Arglist, OldArglist), fail).

?- util_declare(personne_buffer_suppression_desaffectation_db(0,0), fail).

/*******************************************************************************
* Preprocess
*******************************************************************************/
% POint d'entré du specific
personne(preprocess):-
	specific_personne(preprocess),
	fail.
personne(preprocess):-
	% Optimisation du pre-process lors d'un refresh
	(specific_parameter(refresh_optimisation_1, on) ->
            % Renvoie toute les instances sauf si lancer à l'intérieur d'un refresh
            % Ne donne alors que les personnes concernées par une modification récupérée par le refresh
	    refresh_touched_obj(Evt, personne, X)   
	;
	    is_a(X, personne)
	),
	personne(X, preprocess),
	fail.
/*
personne(preprocess):-
	% Renvoie toute les instances sauf si lancer à l'intérieur d'un refresh
	% Donne alors toutes les instances modifiées
%	refresh_touched_obj(Evt, personne, X),
	is_a(X, personne),
	personne(X, preprocess),
	fail.
*/
% Avant le calcul des décomptes du module jour, on initialise les unités 
% des contingents et contingents std (SPECIFIQUE A TSR UNIQUEMENT)
% personne(preprocess):-
% 	writeln(personne(preprocess)),
% 	contingent_std(_, init_unite),
% 	contingent(_, init_unite),
% 	fail.
personne(preprocess):-
	down_role_in_list(planificateur, [micro_planificateur, gestionnaire_micro]),
	is_class(indispo_bar, _, _, _),
	indispo_bar(preprocess),
	fail.
/*
%Déplacer dans le desc
personne(preprocess):-
	down_role_in_list(planificateur, [micro_planificateur, macro_planificateur, gestionnaire_micro]),
	iss_a(X, personne),	
	X@personal_sort_no <- 999,
	fail.
*/
personne(preprocess):-
	down_role_in_list(planificateur, [micro_planificateur, macro_planificateur, gestionnaire_micro]),	
	personal_sort_no(Type_Ressources, X, Personal_sort_no),
	iss_a(X, personne),	
	X@personal_sort_no <- Personal_sort_no,
	writeln(1-X-personal_sort_no-Personal_sort_no),
	fail.	
personne(preprocess).

% PRE-PROCESS INDIVIDUEL
% Détruis toutes les personnes qui n'auraient pas dû être chargées et qui n'ont rien sur leur planning
% = f(all)
personne(P, preprocess):-
	not specific_parameter(preprocess_clean_unused_res, off),

	% Je ne nettoie pas les personnes si j'ai forcé leur chargement (ex: CDD)
	mode@preprocess_clean_unused_res = on,

	down_role_in_list(planificateur, [micro_planificateur, gestionnaire_micro]),
	iss_a(P, personne),
	all(contrat, name, [personne = P, debut < mode@end_date, fin > mode@start_date], [], Cs),
	Cs = [],
	all(etiquette, name, [personne = P, jour_planif >= mode@start_date, jour_planif =< mode@end_date], [], Es),
	all(indispo_planif, name, [ressource = P, date_debut >= mode@start_date, date_debut =< mode@end_date], Es, Is),
	all(doublure_etiquette, name, [personne = P, jour_planif >= mode@start_date, jour_planif =< mode@end_date], Is, DEs),
	DEs = [],
	destroy_instance(P),     % Suppression en mémoire uniquement
	% On supprime également tous les objets associés à cette personne

	$member(Class-Attr, [aptitude-ressource, contrat-personne, contingent-personne, quota-personne, 
			     appart_equipe-ressource, 
			     appart_equipe_cycle-ressource,
			     occupation_grade-personne, occupation_fonction-personne, 
			     appart_societe-ressource, appart_centre-ressource, appart_population-ressource, 
			     due-personne, mission-personne, demande_conges-personne, 
			     excep_remuneration-personne, web_role_personne-personne, 
			     decompte_personne-personne, compteur_annuel-ressource,
			     marqueur-ressource, jour_a_recuperer-personne]),
	iss_class(Class),  % Par sécurité...
	iss_a(Obj, Class),
	Obj@Attr = P,
	destroy_instance(Obj),     % Suppression en mémoire uniquement
	fail.
% = f(contrat, aptitude, planning)
personne(P, preprocess):-
	% Bufferisation des contrats/aptitude/planning
	iss_a(P, personne),
	personne(P, init_array),
	fail.

% = f(contrat)
personne(Name, preprocess):-
	% Afin d''alleger le redressin des gantts, stock le premier contrat trouve pour
	% chaque personne
	personne(Name, update_contrat),
	fail.
% OK
personne(Name, preprocess):-
	iss_a(Name, personne),
	personne(Name, set_label),
	fail.
% % OK
% personne(Name, preprocess):-
% 	% Initialise le panel des chargements des CDD d''usages si utilité
% 	iss_a(Name, personne),
% 	X@numero_matricule = mode@default_matricule_cdd_anonyme,
% 	X@cdd_anonyme <- 1,
% 	fail.
personne(Name, preprocess).







% Verification sans verbose
personne(Name, can_modify(Atts)):-
	personne_check_can_modify(Name, Atts, off).
personne(Name, can_create(Atts)):-
	personne_check_can_modify(Name, Atts, off).
personne(Name, can_destroy).

% Verification avec verbose
personne(Name, check(can_modify(Atts))):-
	personne_check_can_modify(Name, Atts, on).
personne(Name, check(can_create(Atts))):-
	personne_check_can_modify(Name, Atts, on).
personne(Name, check(can_destroy)):-
	personne_check_can_destroy(Name, can_destroy).


% Méthodes de base
personne(Name, new(Atts)):-
	!,
	frm_default_method(personne, new(Name, Atts)),

	% Initialise les arrays
	personne(Name, init_array).
personne(Name, new(Atts)):-
	!,
	frm_default_method(personne, new_light(Name, Atts)).


personne(Name, set_atts(Atts)):-
	frm_default_method(personne, set_atts(Name, Atts)).
personne(Name, destroy):-
	is_class(quota, _,_,_),
	is_a(Q, quota),
	Q@personne = Name,
	quota(Q, destroy),
	fail.
personne(Name, destroy):-
	frm_default_method(personne, destroy(Name)).
personne(Name, init):-
	frm_default_method(personne, init(Name)).

% Méthodes graphiques
personne(Name, update_gui):-
	personne(Name, init_gui),
	fail.
personne(Name, update_gui):-
	Gantt = Name@gantt_parent,
	instance(Gantt),
	gantt(Gantt, redraw_entry(Name)),
	fail.
personne(Name, update_gui):-
	!.

personne(Name, init_gui):-
	personne(Name, recompute_compteur),
	fail.
personne(Name, init_gui):-
	instance((mode@color_by_res)),
	appl_color_by_object(personne, (mode@color_by_res)@attr, Name),
	fail.
personne(Name, init_gui):-
	!.

personne(Name, redraw):-
	mode@view = vue_affectation_macro,
	!,
	vue_affectation_macro_ressource_gantt_redraw(Name).  
personne(Name, redraw):-
	mode@view = vue_affectation_journaliere,
	!,
	vue_affectation_journaliere_ressource_gantt_redraw(Name).  
personne(Name, redraw):-
	!,
	ressource_gantt_redraw(Name).  

% Positionne le label
personne(Item, set_label):-
	make_label_ressource(Item),
	fail.
personne(Item, set_label).



/*******************************************************************************
* Lance le calcul des compteurs sur une personne
*******************************************************************************/
personne(Name, recompute_compteur):-
	mode@view = vue_affectation_macro,
	iss_a(Name, personne),
	writeln('##################################'-RECOMPUTE-COMPTEUR-Name-'############################'),
	% Compteurs en dessous des personnes
	writeln('Compteurs graphique en dessous des personnes'),
	ressource(Name, update_graphical_compteurs),
	% Decomptes personnes
	writeln('Decompte Personnes'),
	vue_affectation_macro_recalcule_decompte(Name),
	list(main_list, redraw),
	gantt(main_gantt, redraw_entry(Name)),
	fail. 
personne(Name, recompute_compteur).





/*******************************************************************************
* Met à jour l''attribut contrat des personnes
*******************************************************************************/
personne(Name, update_contrat):-
	down_role_in_list(planificateur, [micro_planificateur, macro_planificateur, gestionnaire_micro]),
	appl_get_loading_period(From, To),
	!,
	personne(Name, update_contrat(jour_parameter@jour_j, To)).
personne(Name, update_contrat):-
	appl_get_loading_period(From, To),
	mode@now =< To,
	mode@now >= From,
	!,
	personne(Name, update_contrat(mode@now, _)).
personne(Name, update_contrat):-
	appl_get_loading_period(From, _),
	personne(Name, update_contrat(From, _)).


/*******************************************************************************
* Memorize dans l''objet personne son contrat et la colorie selon celui-ci
*******************************************************************************/
% 0- Réinitialise l'attibut contrat
personne(Name, update_contrat(_, _)):-
	iss_a(Name, personne),
	Name@contrat <- 0, 
	fail.
% 1- Contrat englobant le jour courant
personne(Name, update_contrat(From0, _)):-
	From is (From0/1440)*1440,
	(var(Name) ->
	    contrat(_, get_contrats(name, [debut =< From, fin >= From], Cs))
	;
	    personne(Name, get_contrats(name, [debut =< From, fin >= From], Cs))
	),
        util_keep_one_instance(Cs, personne, debut, Cs_Sorted),
        $member(C, Cs_Sorted),
	instance(C@personne),
	% Vérifie que le type de contrat existe
	instance(C@type_contrat),
        (C@personne)@contrat <- C,
        (C@personne)@color <- (C@type_contrat)@couleur,
	fail.
% 2- Contrat englobant le premier jour chargé
personne(Name, update_contrat(_, _)):-
	From is (mode@start_date/1440)*1440,
	iss_a(Name, personne),
	not instance(Name@contrat),
	personne(Name, get_contrat(name, [], C)),
	C@debut/1440 =< From/1440,
	C@fin/1440 >= From/1440,
	not instance((C@personne)@contrat),
	instance(C@personne),
	% Vérifie que le type de contrat existe
	instance(C@type_contrat),
	(C@personne)@contrat <- C,
	(C@personne)@color <- (C@type_contrat)@couleur,
	fail.
% 3- Contrat au hasard démarrant avant la période...
personne(Name, update_contrat(From, To)):-
	iss_a(Name, personne),
	not instance(Name@contrat),	
	personne(Name, get_contrat(name, [], C)),
	C@debut/1440 =< From/1440,
	not instance((C@personne)@contrat),
	instance(C@personne),
	% Vérifie que le type de contrat existe
	instance(C@type_contrat),
	(C@personne)@contrat <- C,
	(C@personne)@color <- (C@type_contrat)@couleur,
	fail.
% 3- Contrat au hasard démarrant après la période...
personne(Name, update_contrat(From, To)):-
	iss_a(Name, personne),
	not instance(Name@contrat),
	personne(Name, get_contrat(name, [], C)),
	C@debut/1440 > From/1440,
	not instance((C@personne)@contrat),
	instance(C@personne),
	% Vérifie que le type de contrat existe
	instance(C@type_contrat),
	(C@personne)@contrat <- C,
	(C@personne)@color <- (C@type_contrat)@couleur,
	fail.
personne(Name, update_contrat(From, To)):-
	iss_a(Name, personne),
	instance(mode@color_by_res),
	appl_color_by_object(personne, (mode@color_by_res)@attr, Name),
	fail.
personne(Name, update_contrat(From, To)).




/*******************************************************************************
*
*******************************************************************************/
%Vérifie et Récupére le métier principal
personne(Personne, metier_principal(From, To, TypeRessource)):-
	ressource(Personne, metier_principal(From, To, TypeRessource)).

%Vérifie et Récupére le métier secondaire (et non principal)
personne(Personne, metier_secondaire(From, To, TypeRessource)):-
	ressource(Personne, metier_secondaire(From, To, TypeRessource)).

%Vérifie et Récupére le métier
personne(Personne, metier_principal_secondaire(From, To, TypeRessource)):-
	ressource(Personne, metier_principal_secondaire(From, To, TypeRessource)).




% Recupère le label
personne(_, get_label(Label)):-
	personne(Name, get_label(long, Label)).

personne(Name, get_label(_, Label)):-
	Contrat = Name@contrat,
	(instance(Contrat) ->
	    TContrat = (Contrat@type_contrat)@nom
	;
	    TContrat = '-'),
	sprintf(Label, "%s %s (%s)", [Name@nom, Name@prenom, TContrat]).

% Regroupe les personnes qui ont un contrat et qui n''ont pas
personne(List, get_gr_contrat(List1, List2)):-
	personne_get_gr_contrat(List, List1, List2).

% Regroupe les personnes permamants/non permamant/ pas de contrat
personne(List, get_gr_contrat(List1, List2, List3)):-
	personne_get_gr_contrat(List, List1, List2, List3).


% Donne les personnes qui ont une 'indispo, etiquette, doubure, marqueur' sur la période de visualisation
personne(List, get_personne_objet_in_period(From, To, List1, List2)):-
	personne_get_personne_objet_in_period(List, From, To, List1, List2).


%Méthodes DB
personne(_, db_download(Cond)):-
	frm_default_method(personne, db_download('OPTI_PERSONNE', Cond, [
		"OPTI_PERSONNE.DB_KEY"-db_key,
		"OPTI_PERSONNE.NUMERO_MATRICULE"-numero_matricule, 
		"OPTI_PERSONNE.ABREVIATION"-abreviation, 
		"OPTI_PERSONNE.COMMON_NAME"-common_name, 
		"OPTI_PERSONNE.NOM"-nom, 
		"OPTI_PERSONNE.PRENOM"-prenom, 
		"OPTI_PERSONNE.NOM_JEUNE_FILLE"-nom_jeune_fille, 
		"OPTI_PERSONNE.SEXE"-sexe, 
		"OPTI_PERSONNE.RUE"-rue, 
		"OPTI_PERSONNE.PAYS_NUMERO_POSTAL_LOCAL"-pays_numero_postal_localite, 
		"OPTI_PERSONNE.ADRESSE1"-adresse1, 
		"OPTI_PERSONNE.ADRESSE2"-adresse2, 
		"OPTI_PERSONNE.CODE_POSTAL"-code_postal, 
		"OPTI_PERSONNE.VILLE"-ville, 
		"OPTI_PERSONNE.PAYS"-pays, 
		"OPTI_PERSONNE.TELEPHONE1"-telephone1, 
		"OPTI_PERSONNE.TELEPHONE2"-telephone2, 
		"OPTI_PERSONNE.TELEPHONE3"-telephone3, 
		"OPTI_PERSONNE.TELEPHONE1_PUBLIABLE"-telephone1_publiable, 
		"OPTI_PERSONNE.TELEPHONE2_PUBLIABLE"-telephone2_publiable, 
		"OPTI_PERSONNE.TELEPHONE3_PUBLIABLE"-telephone3_publiable, 
		"OPTI_PERSONNE.EMAIL1"-email1, 
		"OPTI_PERSONNE.EMAIL2"-email2,
		"OPTI_PERSONNE.EMAIL3"-email3,
		"OPTI_PERSONNE.MAIL1_PUBLIABLE"-mail1_publiable, 
		"OPTI_PERSONNE.MAIL2_PUBLIABLE"-mail2_publiable, 
		"OPTI_PERSONNE.MAIL3_PUBLIABLE"-mail3_publiable,

		"OPTI_PERSONNE.SI_EMAIL1_DEMAT"-si_email1_demat,
		"OPTI_PERSONNE.SI_EMAIL2_DEMAT"-si_email2_demat,
		"OPTI_PERSONNE.SI_EMAIL3_DEMAT"-si_email3_demat,
		"OPTI_PERSONNE.SI_TELEPHONE1_DEMAT"-si_telephone1_demat,
		"OPTI_PERSONNE.SI_TELEPHONE2_DEMAT"-si_telephone2_demat,
		"OPTI_PERSONNE.SI_TELEPHONE3_DEMAT"-si_telephone3_demat,

		$date_to_julian$("OPTI_PERSONNE.DATE_ENTREE_SOCIETE")-date_entree_societe,
		$date_to_julian$("OPTI_PERSONNE.DATE_SORTIE_SOCIETE")-date_sortie_societe, 
		"OPTI_PERSONNE.SI_WEB_VISIBLE"-si_web_visible,

		"OPTI_PERSONNE.REMARQUE"-remarque, 
		"OPTI_PERSONNE.RENSEIGNEMENTS"-renseignements,
		"OPTI_PERSONNE.RENS_NUM_CARTE_SEJOUR"-rens_num_carte_sejour,
		$date_to_julian$("OPTI_PERSONNE.RENS_DATE_CARTE_SEJOUR")-rens_date_carte_sejour,
		"OPTI_PERSONNE.RENS_DUREE_CARTE_SEJOUR"-rens_duree_carte_sejour,
		"OPTI_PERSONNE.RENS_AUTORITE_CARTE_SEJOUR"-rens_autorite_carte_sejour,
		"OPTI_PERSONNE.RENS_NUM_CARTE_TRAVAIL"-rens_num_carte_travail,
		$date_to_julian$("OPTI_PERSONNE.RENS_DATE_CARTE_TRAVAIL")-rens_date_carte_travail,
		"OPTI_PERSONNE.RENS_DUREE_CARTE_TRAVAIL"-rens_duree_carte_travail,
		"OPTI_PERSONNE.RENS_METIER_CARTE_TRAVAIL"-rens_metier_carte_travail,
		"OPTI_PERSONNE.NUMERO_SPECTACLE"-numero_spectacle, 
		"OPTI_PERSONNE.CARTE_DE_PRESSE"-carte_de_presse, 
		$date_to_julian$("OPTI_PERSONNE.DATE_OBTENTION")-date_obtention, 
		"OPTI_PERSONNE.SECURITE_SOCIALE"-securite_sociale, 
		"OPTI_PERSONNE.NATIONALITE"-nationalite, 
		$date_to_julian$("OPTI_PERSONNE.DATE_NAISSANCE")-date_naissance,
		"OPTI_PERSONNE.COMMUNE_NAISSANCE"-commune_naissance,
		"OPTI_PERSONNE.DEP_NAISSANCE"-dep_naissance,
		"OPTI_PERSONNE.PAYS_NAISSANCE"-pays_naissance,
		$date_to_julian$("OPTI_PERSONNE.TIME_STAMP")-time_stamp,
		$date_to_julian$("OPTI_PERSONNE.TAG_INDISPO_PLANIF")-tag_indispo_planif,
		$date_to_julian$("OPTI_PERSONNE.TAG_DOUBLURE")-tag_doublure,
		$date_to_julian$("OPTI_PERSONNE.TAG_MARQUEUR")-tag_marqueur,
		"OPTI_PERSONNE.PASSWORD"-password,
		"OPTI_PERSONNE.SI_AUTH_OPTI"-si_auth_opti,		
		"OPTI_PERSONNE.SI_PREFERENCE_H"-si_preference_h,
		"OPTI_PERSONNE.SI_LUNDI"-si_lundi,
		"OPTI_PERSONNE.LUNDI_HEURE_DEBUT"-lundi_heure_debut,
		"OPTI_PERSONNE.LUNDI_HEURE_FIN"-lundi_heure_fin,
		"OPTI_PERSONNE.SI_MARDI"-si_mardi,
		"OPTI_PERSONNE.MARDI_HEURE_DEBUT"-mardi_heure_debut,
		"OPTI_PERSONNE.MARDI_HEURE_FIN"-mardi_heure_fin,
		"OPTI_PERSONNE.SI_MERCREDI"-si_mercredi,
		"OPTI_PERSONNE.MERCREDI_HEURE_DEBUT"-mercredi_heure_debut,
		"OPTI_PERSONNE.MERCREDI_HEURE_FIN"-mercredi_heure_fin,
		"OPTI_PERSONNE.SI_JEUDI"-si_jeudi,
		"OPTI_PERSONNE.JEUDI_HEURE_DEBUT"-jeudi_heure_debut,
		"OPTI_PERSONNE.JEUDI_HEURE_FIN"-jeudi_heure_fin,
		"OPTI_PERSONNE.SI_VENDREDI"-si_vendredi,
		"OPTI_PERSONNE.VENDREDI_HEURE_DEBUT"-vendredi_heure_debut,
		"OPTI_PERSONNE.VENDREDI_HEURE_FIN"-vendredi_heure_fin,
		"OPTI_PERSONNE.SI_SAMEDI"-si_samedi,
		"OPTI_PERSONNE.SAMEDI_HEURE_DEBUT"-samedi_heure_debut,
		"OPTI_PERSONNE.SAMEDI_HEURE_FIN"-samedi_heure_fin,
		"OPTI_PERSONNE.SI_DIMANCHE"-si_dimanche,
		"OPTI_PERSONNE.DIMANCHE_HEURE_DEBUT"-dimanche_heure_debut,
		"OPTI_PERSONNE.DIMANCHE_HEURE_FIN"-dimanche_heure_fin,
		"OPTI_PERSONNE.CDD_ANONYME"-cdd_anonyme,
		"'responsable_rh_'||OPTI_PERSONNE.RESPONSABLE_RH1"-responsable_rh1,
		"'responsable_rh_'||OPTI_PERSONNE.RESPONSABLE_RH2"-responsable_rh2,
		"OPTI_PERSONNE.SI_NON_DEMATERIALISATION"-si_non_dematerialisation,
		"OPTI_PERSONNE.VILLE_PUBLIABLE"-ville_publiable,
		$date_to_julian$("OPTI_PERSONNE.DATE_DISPO_REALISE_P")-date_dispo_realise_p,
		$date_to_julian$("OPTI_PERSONNE.DATE_DISPO_REALISE_R")-date_dispo_realise_r,
		$date_to_julian$("OPTI_PERSONNE.DATE_DISPO_REALISE_G")-date_dispo_realise_g,
		$date_to_julian$("OPTI_PERSONNE.DATE_VALIDATION_REALISE")-date_validation_realise,
		"OPTI_PERSONNE.SI_WEB_IGNORE"-si_web_ignore
		

])).
personne(_, db_upload):-
	frm_default_method(personne, db_upload('OPTI_PERSONNE', Cond, [
		"OPTI_PERSONNE.DB_KEY"-X@db_key,
		"OPTI_PERSONNE.NUMERO_MATRICULE"-numero_matricule-$atom_to_char$(X@numero_matricule), 
		"OPTI_PERSONNE.ABREVIATION"-abreviation-$atom_to_char$(X@abreviation), 
		"OPTI_PERSONNE.COMMON_NAME"-common_name-$atom_to_char$(X@common_name), 
		"OPTI_PERSONNE.NOM"-nom-$atom_to_char$(X@nom), 
		"OPTI_PERSONNE.PRENOM"-prenom-$atom_to_char$(X@prenom), 
		"OPTI_PERSONNE.NOM_JEUNE_FILLE"-nom_jeune_fille-$atom_to_char$(X@nom_jeune_fille), 
		"OPTI_PERSONNE.SEXE"-sexe-X@sexe, 
		"OPTI_PERSONNE.RUE"-rue-$atom_to_char$(X@rue), 
		"OPTI_PERSONNE.PAYS_NUMERO_POSTAL_LOCAL"-pays_numero_postal_localite-$atom_to_char$(X@pays_numero_postal_localite), 
		"OPTI_PERSONNE.ADRESSE1"-adresse1-$atom_to_char$(X@adresse1), 
		"OPTI_PERSONNE.ADRESSE2"-adresse2-$atom_to_char$(X@adresse2), 
		"OPTI_PERSONNE.CODE_POSTAL"-code_postal-$atom_to_char$(X@code_postal), 
		"OPTI_PERSONNE.VILLE"-ville-$atom_to_char$(X@ville), 
		"OPTI_PERSONNE.PAYS"-pays-$atom_to_char$(X@pays), 
		"OPTI_PERSONNE.TELEPHONE1"-telephone1-$atom_to_char$(X@telephone1), 
		"OPTI_PERSONNE.TELEPHONE2"-telephone2-$atom_to_char$(X@telephone2), 
		"OPTI_PERSONNE.TELEPHONE3"-telephone3-$atom_to_char$(X@telephone3), 
		"OPTI_PERSONNE.TELEPHONE1_PUBLIABLE"-telephone1_publiable-X@telephone1_publiable, 
		"OPTI_PERSONNE.TELEPHONE2_PUBLIABLE"-telephone2_publiable-X@telephone2_publiable, 
		"OPTI_PERSONNE.TELEPHONE3_PUBLIABLE"-telephone3_publiable-X@telephone3_publiable,
		"OPTI_PERSONNE.EMAIL1"-email1-$atom_to_char$(X@email1), 
		"OPTI_PERSONNE.EMAIL2"-email2-$atom_to_char$(X@email2), 
		"OPTI_PERSONNE.EMAIL3"-email3-$atom_to_char$(X@email3), 
		"OPTI_PERSONNE.MAIL1_PUBLIABLE"-mail1_publiable-X@mail1_publiable, 
		"OPTI_PERSONNE.MAIL2_PUBLIABLE"-mail2_publiable-X@mail2_publiable, 
		"OPTI_PERSONNE.MAIL3_PUBLIABLE"-mail3_publiable-X@mail3_publiable,

		"OPTI_PERSONNE.SI_EMAIL1_DEMAT"-si_email1_demat-X@si_email1_demat,
		"OPTI_PERSONNE.SI_EMAIL2_DEMAT"-si_email2_demat-X@si_email2_demat,
		"OPTI_PERSONNE.SI_EMAIL3_DEMAT"-si_email3_demat-X@si_email3_demat,
		"OPTI_PERSONNE.SI_TELEPHONE1_DEMAT"-si_telephone1_demat-X@si_telephone1_demat,
		"OPTI_PERSONNE.SI_TELEPHONE2_DEMAT"-si_telephone2_demat-X@si_telephone2_demat,
		"OPTI_PERSONNE.SI_TELEPHONE3_DEMAT"-si_telephone3_demat-X@si_telephone3_demat,

		"OPTI_PERSONNE.DATE_ENTREE_SOCIETE"-date_entree_societe-$julian_to_date$(X@date_entree_societe),
		"OPTI_PERSONNE.DATE_SORTIE_SOCIETE"-date_sortie_societe-$julian_to_date$(X@date_sortie_societe),
		"OPTI_PERSONNE.SI_WEB_VISIBLE"-si_web_visible-X@si_web_visible,
		"OPTI_PERSONNE.REMARQUE"-remarque-$atom_to_char$(X@remarque), 
		"OPTI_PERSONNE.RENSEIGNEMENTS"-renseignements-$atom_to_char$(X@renseignements),
		"OPTI_PERSONNE.RENS_NUM_CARTE_SEJOUR"-rens_num_carte_sejour-$atom_to_char$(X@rens_num_carte_sejour),
		"OPTI_PERSONNE.RENS_DATE_CARTE_SEJOUR"-rens_date_carte_sejour-$julian_to_date$(X@rens_date_carte_sejour),
		"OPTI_PERSONNE.RENS_DUREE_CARTE_SEJOUR"-rens_duree_carte_sejour-$atom_to_char$(X@rens_duree_carte_sejour),
		"OPTI_PERSONNE.RENS_AUTORITE_CARTE_SEJOUR"-rens_autorite_carte_sejour-$atom_to_char$(X@rens_autorite_carte_sejour),
		"OPTI_PERSONNE.RENS_NUM_CARTE_TRAVAIL"-rens_num_carte_travail-$atom_to_char$(X@rens_num_carte_travail),
		"OPTI_PERSONNE.RENS_DATE_CARTE_TRAVAIL"-rens_date_carte_travail-$julian_to_date$(X@rens_date_carte_travail),
		"OPTI_PERSONNE.RENS_DUREE_CARTE_TRAVAIL"-rens_duree_carte_travail-$atom_to_char$(X@rens_duree_carte_travail),
		"OPTI_PERSONNE.RENS_METIER_CARTE_TRAVAIL"-rens_metier_carte_travail-$atom_to_char$(X@rens_metier_carte_travail),
		"OPTI_PERSONNE.NUMERO_SPECTACLE"-numero_spectacle-$atom_to_char$(X@numero_spectacle), 
		"OPTI_PERSONNE.CARTE_DE_PRESSE"-carte_de_presse-$atom_to_char$(X@carte_de_presse), 
		"OPTI_PERSONNE.DATE_OBTENTION"-date_obtention-$julian_to_date$(X@date_obtention), 
		"OPTI_PERSONNE.SECURITE_SOCIALE"-securite_sociale-$atom_to_char$(X@securite_sociale),
		"OPTI_PERSONNE.NATIONALITE"-nationalite-$atom_to_char$(X@nationalite),  	
		"OPTI_PERSONNE.DATE_NAISSANCE"-date_naissance-$julian_to_date$(X@date_naissance),
		"OPTI_PERSONNE.COMMUNE_NAISSANCE"-commune_naissance-$atom_to_char$(X@commune_naissance),
		"OPTI_PERSONNE.DEP_NAISSANCE"-dep_naissance-$atom_to_char$(X@dep_naissance),
		"OPTI_PERSONNE.PAYS_NAISSANCE"-pays_naissance-$atom_to_char$(X@pays_naissance),
		"OPTI_PERSONNE.TIME_STAMP"-upload_date-$julian_to_date$(mode@upload_date),
		"OPTI_PERSONNE.TAG_INDISPO_PLANIF"-tag_indispo_planif-$julian_to_date$(X@tag_indispo_planif),
		"OPTI_PERSONNE.TAG_DOUBLURE"-tag_doublure-$julian_to_date$(X@tag_doublure),
		"OPTI_PERSONNE.TAG_MARQUEUR"-tag_marqueur-$julian_to_date$(X@tag_marqueur),
		"OPTI_PERSONNE.PASSWORD"-password-$atom_to_char$(X@password),
		"OPTI_PERSONNE.SI_AUTH_OPTI"-si_auth_opti-X@si_auth_opti,		
		"OPTI_PERSONNE.SI_PREFERENCE_H"-si_preference_h-X@si_preference_h,
		"OPTI_PERSONNE.SI_LUNDI"-si_lundi-X@si_lundi,
		"OPTI_PERSONNE.LUNDI_HEURE_DEBUT"-lundi_heure_debut-X@lundi_heure_debut,
		"OPTI_PERSONNE.LUNDI_HEURE_FIN"-lundi_heure_fin-X@lundi_heure_fin,
		"OPTI_PERSONNE.SI_MARDI"-si_mardi-X@si_mardi,
		"OPTI_PERSONNE.MARDI_HEURE_DEBUT"-mardi_heure_debut-X@mardi_heure_debut,
		"OPTI_PERSONNE.MARDI_HEURE_FIN"-mardi_heure_fin-X@mardi_heure_fin,
		"OPTI_PERSONNE.SI_MERCREDI"-si_mercredi-X@si_mercredi,
		"OPTI_PERSONNE.MERCREDI_HEURE_DEBUT"-mercredi_heure_debut-X@mercredi_heure_debut,
		"OPTI_PERSONNE.MERCREDI_HEURE_FIN"-mercredi_heure_fin-X@mercredi_heure_fin,
		"OPTI_PERSONNE.SI_JEUDI"-si_jeudi-X@si_jeudi,
		"OPTI_PERSONNE.JEUDI_HEURE_DEBUT"-jeudi_heure_debut-X@jeudi_heure_debut,
		"OPTI_PERSONNE.JEUDI_HEURE_FIN"-jeudi_heure_fin-X@jeudi_heure_fin,
		"OPTI_PERSONNE.SI_VENDREDI"-si_vendredi-X@si_vendredi,
		"OPTI_PERSONNE.VENDREDI_HEURE_DEBUT"-vendredi_heure_debut-X@vendredi_heure_debut,
		"OPTI_PERSONNE.VENDREDI_HEURE_FIN"-vendredi_heure_fin-X@vendredi_heure_fin,
		"OPTI_PERSONNE.SI_SAMEDI"-si_samedi-X@si_samedi,
		"OPTI_PERSONNE.SAMEDI_HEURE_DEBUT"-samedi_heure_debut-X@samedi_heure_debut,
		"OPTI_PERSONNE.SAMEDI_HEURE_FIN"-samedi_heure_fin-X@samedi_heure_fin,
		"OPTI_PERSONNE.SI_DIMANCHE"-si_dimanche-X@si_dimanche,
		"OPTI_PERSONNE.DIMANCHE_HEURE_DEBUT"-dimanche_heure_debut-X@dimanche_heure_debut,
		"OPTI_PERSONNE.DIMANCHE_HEURE_FIN"-dimanche_heure_fin-X@dimanche_heure_fin,
		"OPTI_PERSONNE.CDD_ANONYME"-X@cdd_anonyme,
		"OPTI_PERSONNE.RESPONSABLE_RH1"-responsable_rh1-substr(X@responsable_rh1, 16),
 		"OPTI_PERSONNE.RESPONSABLE_RH2"-responsable_rh2-substr(X@responsable_rh2, 16),
		"OPTI_PERSONNE.VILLE_PUBLIABLE"-ville_publiable-X@ville_publiable,
		"OPTI_PERSONNE.SI_NON_DEMATERIALISATION"-si_non_dematerialisation-X@si_non_dematerialisation,
		"OPTI_PERSONNE.DATE_DISPO_REALISE_P"-date_dispo_realise_p-$julian_to_date$(X@date_dispo_realise_p),
		"OPTI_PERSONNE.DATE_DISPO_REALISE_R"-date_dispo_realise_r-$julian_to_date$(X@date_dispo_realise_r),
		"OPTI_PERSONNE.DATE_DISPO_REALISE_G"-date_dispo_realise_g-$julian_to_date$(X@date_dispo_realise_g),
		"OPTI_PERSONNE.DATE_VALIDATION_REALISE"-date_validation_realise-$julian_to_date$(X@date_validation_realise),
		"OPTI_PERSONNE.SI_WEB_IGNORE"-X@si_web_ignore
	    ],
	X:[])).


% Tag les personnes qui ont été modifiées
personne( _, db_after_upload):-
	specific_personne(_, db_after_upload),
	fail.
personne( _, db_after_upload):-
	appl_db_refresh_mark_personne_tag,
	fail.
% Methodes liees au panel sortie societe
personne( _, db_after_upload):-
	%% Prédicat qui a mémorisé la personne et la date de sortie
	personne_buffer_suppression_desaffectation_db(Personne, Date),

	writeln(after_upload_sortie_societe),

	%% Méthode appelant les requêtes de suppression et de désaffectation
$rem	personne_suppression_desaffectation_db(Personne, Date),
	fail.
personne( _, db_after_upload).


personne(_, db_delete):-
	frm_default_method(personne, db_delete('OPTI_PERSONNE')).


% Point d'entrée du specific (inutile de le déclarer en entete)
personne(_, db_cond(Cond)):-
	specific_personne(_, db_cond(Cond, Goal)),
	!,
	Goal.
% TEMPORARY TABLE
personne(_, db_cond(Cond)):-
	down_role(Role, Type),
	$is_member_of(Role-Type, [_-gestionnaire_equipe, _-equipe, _-type_ressource, _-gestionnaire,
	                          _-micro_planificateur, _-gestionnaire_micro, _-besoin_micro]),
	temporary_table(temporary_table, prepare),
	!,	
	sprintf(Cond,  ", TEMPORARY_PERSONNES where OPTI_PERSONNE.DB_KEY = TEMPORARY_PERSONNES.DB_KEY", 
		      []).

% Macro-Planificateur : Personnes ayant une aptitude sur la direction et la période chargées
personne(_, db_cond(Cond)):-
	down_role(planificateur, macro_planificateur),
	Direction = jour_parameter@direction,
	instance(Direction),	
	!,
	appl_get_loading_period(From, To),
	frm_date_convert(From, get_db(Debut)),
	frm_date_convert(To, get_db(Fin)),	
	sprintf(Cond, " where OPTI_PERSONNE.DB_KEY in 
		        (select OPTI_APTITUDE.RESSOURCE from OPTI_APTITUDE, OPTI_DEMANDE_RESSOURCE, OPTI_TYPE_RESSOURCE_DIRE where 
		                OPTI_APTITUDE.DATE_DEBUT <= %s and OPTI_APTITUDE.DATE_FIN >= %s and 
			        OPTI_APTITUDE.DEMANDE_RESSOURCE = OPTI_DEMANDE_RESSOURCE.DB_KEY and
			        OPTI_DEMANDE_RESSOURCE.TYPE_RESSOURCE = OPTI_TYPE_RESSOURCE_DIRE.TYPE_RESSOURCE and 
			        OPTI_TYPE_RESSOURCE_DIRE.DIRECTION = %d AND
			        OPTI_TYPE_RESSOURCE_DIRE.DATE_DEBUT <= %s AND OPTI_TYPE_RESSOURCE_DIRE.DATE_FIN >= %s )", [Fin, Debut, Direction@db_key, Fin, Debut]).

% Micro-Planificateur, Gestionnaire Micro : Personnes appartenant à l'équipe chargée sur la macro-période
personne(_, db_cond(Cond)):-
	down_role_in_list(planificateur, [micro_planificateur, gestionnaire_micro, besoin_micro]),
	Equipe_Red = jour_parameter@equipe_redactionnelle,	
	instance(Equipe_Red),	
	!,
	appl_get_loading_period(auto, From, To),
	frm_date_convert(From, get_db(Debut)),
	frm_date_convert(To, get_db(Fin)),
	sprintf(Cond,  " where OPTI_PERSONNE.DB_KEY in 
                         (select OPTI_APPART_EQUIPE.RESSOURCE from OPTI_APPART_EQUIPE where 
		                 OPTI_APPART_EQUIPE.DATE_DEBUT <= %s AND OPTI_APPART_EQUIPE.DATE_FIN >= %s and	
				 OPTI_APPART_EQUIPE.EQUIPE_REDACTIONNELLE = %s)", 
		      [Fin, Debut, Equipe_Red@db_key]).


% Planificateur /Simulateur Ressources : Personnes ayant une aptitude sur un des métiers chargés
personne(_, db_cond(Cond)):-
	(
	    down_role(planificateur, type_ressource)
	; 
	    down_role(planificateur, absence)
	;
	    down_role(simulateur, type_ressource)
	),
	!,
	db_cond_grp(Loading_Object_Cond),
	appl_get_loading_period(auto, From, To),
	frm_date_convert(From, get_db(Debut)),
	frm_date_convert(To, get_db(Fin)),
	sprintf(Cond, ",OPTI_APTITUDE, OPTI_DEMANDE_RESSOURCE
	                Where
		             OPTI_APTITUDE.DATE_DEBUT <= %s and OPTI_APTITUDE.DATE_FIN >= %s and 
	                     opti_aptitude.ressource = opti_personne.db_key and
                             opti_aptitude.demande_ressource = opti_demande_ressource.db_key and
	                     opti_demande_ressource.type_ressource %s",
	               [Fin, Debut, Loading_Object_Cond]).

% Planificateur Equipe, Planificateur gestionnaire_equipe et Simulateur Equipe  : Personnes appartenant à l'équipe chargée sur la période
personne(_, db_cond(Cond)):-
	down_role(Role, Type),
	$is_member_of(Role-Type, [planificateur-gestionnaire_equipe, planificateur-equipe, simulateur-equipe]),
	(mode@role)@si_super_role = '1',
	Equipe_Red = jour_parameter@equipe_redactionnelle,	
	Direction = Equipe_Red@direction,
	instance(Direction),
	dummy_cumul_annuel_download_periode(mode@start_date, mode@end_date, DD_Chargement0, DF_Chargement0),
	% Ajustement pour le calcul des vacations charge 1 jour avant la période de chargement et 1 jour après en plus de l''agrandissement sur la semaine
	DD_Chargement is DD_Chargement0 - 1 * 1440,
	DF_Chargement is DF_Chargement0 + 1 * 1440,
	frm_date_convert(DD_Chargement, get_db(Debut)),
	frm_date_convert(DF_Chargement, get_db(Fin)),	
	!,
	sprintf(Cond, " where OPTI_PERSONNE.DB_KEY in 
                          (SELECT OPTI_APPART_EQUIPE.RESSOURCE from OPTI_EQUIPE_REDACTIONNEL, OPTI_APPART_EQUIPE where 
		                 OPTI_APPART_EQUIPE.DATE_DEBUT <= %s AND OPTI_APPART_EQUIPE.DATE_FIN >= %s and	
				 OPTI_APPART_EQUIPE.EQUIPE_REDACTIONNELLE = OPTI_EQUIPE_REDACTIONNEL.DB_KEY and 
			         OPTI_EQUIPE_REDACTIONNEL.DIRECTION = %s
			  UNION 
		          SELECT OPTI_TACHE_CYCLIQUE.RESSOURCE FROM OPTI_TACHE_CYCLIQUE, OPTI_CANEVAS_T, OPTI_EQUIPE_REDACTIONNEL WHERE 
		                 OPTI_TACHE_CYCLIQUE.CANEVAS_T = OPTI_CANEVAS_T.DB_KEY AND
		                 OPTI_TACHE_CYCLIQUE.JOUR_PLANIFIE <= %s AND OPTI_TACHE_CYCLIQUE.JOUR_PLANIFIE >= %s AND 
			         OPTI_CANEVAS_T.EQUIPE_REDACTIONNELLE = OPTI_EQUIPE_REDACTIONNEL.DB_KEY and 
			         OPTI_EQUIPE_REDACTIONNEL.DIRECTION = %s)", 
		      [Fin, Debut, Direction@db_key, Fin, Debut, Direction@db_key]).
personne(_, db_cond(Cond)):-
	down_role(Role, Type),
	$is_member_of(Role-Type, [planificateur-gestionnaire_equipe, planificateur-equipe, simulateur-equipe]),
	dummy_cumul_annuel_download_periode(mode@start_date, mode@end_date, DD_Chargement0, DF_Chargement0),
	% Ajustement pour le calcul des vacations charge 1 jour avant la période de chargement et 1 jour après en plus de l''agrandissement sur la semaine
	DD_Chargement is DD_Chargement0 - 1 * 1440,
	DF_Chargement is DF_Chargement0 + 1 * 1440,
	frm_date_convert(DD_Chargement, get_db(Debut)),
	frm_date_convert(DF_Chargement, get_db(Fin)),	
	db_cond_grp(Loading_Object_Cond),
	!,
	sprintf(Cond, " where OPTI_PERSONNE.DB_KEY in 
                          (SELECT OPTI_APPART_EQUIPE.RESSOURCE from OPTI_EQUIPE_REDACTIONNEL, OPTI_APPART_EQUIPE where 
		                 OPTI_APPART_EQUIPE.DATE_DEBUT <= %s AND OPTI_APPART_EQUIPE.DATE_FIN >= %s and	
				 OPTI_APPART_EQUIPE.EQUIPE_REDACTIONNELLE = OPTI_EQUIPE_REDACTIONNEL.DB_KEY and 
			         OPTI_EQUIPE_REDACTIONNEL.DB_KEY %s
			  UNION 
		          SELECT OPTI_TACHE_CYCLIQUE.RESSOURCE FROM OPTI_TACHE_CYCLIQUE, OPTI_CANEVAS_T WHERE 
		                 OPTI_TACHE_CYCLIQUE.CANEVAS_T = OPTI_CANEVAS_T.DB_KEY AND
		                 OPTI_TACHE_CYCLIQUE.JOUR_PLANIFIE <= %s AND OPTI_TACHE_CYCLIQUE.JOUR_PLANIFIE >= %s AND 
			         OPTI_CANEVAS_T.EQUIPE_REDACTIONNELLE %s)", 
		      [Fin, Debut, Loading_Object_Cond, Fin, Debut, Loading_Object_Cond]).

personne(_, db_cond(Cond)):-
	down_role(administrateur),
	!,
	personne_cond_sortie_societe(Cond_Sortie),
	sprintf(Cond, " where %s", [Cond_Sortie]).
% Sinon : Pas tout charger
personne(_, db_cond('')).


/*******************************************************************************
* filtre les personnes selon leur date de sortie société
*******************************************************************************/
personne_cond_sortie_societe(Cond_Sortie):-
	not specific_parameter(date_sortie_societe_filtre_personne, off),
	!,
	appl_get_loading_period(auto, From, To),
	frm_date_convert(From, get_db(Debut)),
	sprintf(Cond_Sortie, "OPTI_PERSONNE.DATE_SORTIE_SOCIETE > %s", [Debut]).
personne_cond_sortie_societe('OPTI_PERSONNE.DB_KEY = OPTI_PERSONNE.DB_KEY').



% point d''entréé spécifique
personne(_, check(db_before_upload)):-
	not specific_personne_check_db_before_upload,
	!,
	fail.
%Vérification en base de l''unicité de muméro de matricule
personne(_, check(db_before_upload)):-
	not specific_parameter(personne_matricule_unique, off),
	not appl_batch_session,
	iss_a(Personne, personne),
	Personne@modified \= 'old',	
	Personne@numero_matricule \= 'ANONYM',
	Personne@numero_matricule \= '?',
	Personne@numero_matricule \= ' ',
	upload_remove_quote(Personne@numero_matricule, Matricule),
	mu_db_tuple("select 'ressource_'||db_key, nom, prenom from opti_personne where numero_matricule = '%s'", [Matricule], Tuples),
        Tuples = tuple(Res, Nom, Prenom), 	
	Res \= Personne,
%??	not instance(Res),	
	sprintf(Msg, "Mise à jour impossible. Le matricule %s défini sur %s %s est déja présent en base de données sur %s %s.\nVeuillez modifier le numéro de matricule.", [Personne@numero_matricule, Personne@nom, Personne@prenom, Nom, Prenom]),
	alert(Msg, [text@ok], _),
	!,
	fail.
personne(_, check(db_before_upload)):-
	not specific_parameter(personne_homonyme, off),
	not appl_batch_session,
	iss_a(Personne, personne),
	Personne@modified \= 'old',
	Personne@numero_matricule \= 'ANONYM',
	Personne@numero_matricule \= '?',
	Personne@numero_matricule \= ' ',
	upload_remove_quote(Personne@nom, Nom),
	upload_remove_quote(Personne@prenom, Prenom),
	mu_db_tuple("select 'ressource_'||db_key, nom, prenom, numero_matricule from opti_personne where nom = '%s' and prenom = '%s' ", 
                       [Nom, Prenom], Tuples),
        Tuples = tuple(Res, _, _, Numero_Matricule),
	Res \= Personne,
	sprintf(Msg, "Attention: Un collaborateur modifié (%s %s %s) possède un homonyme (%s).\nVoulez vous continuer?.", [Personne@numero_matricule, Personne@nom, Personne@prenom, Numero_Matricule]),
	alert(Msg, [text@ok, text@no], Reponse),
	Reponse = text@no,
	!,
	fail.
% Vérification en base du CN
personne(_, check(db_before_upload)):-
	specific_parameter(personne_common_name_unique, on),
	not appl_batch_session,
	iss_a(Personne, personne),
	Personne@modified \= 'old',	
	Personne@numero_matricule \= 'ANONYM',
	personne_cn_normalize(Personne@common_name, CN1_Norm),
	upload_remove_quote(CN1_Norm, CN1),
	mu_db_tuple("select 'ressource_'||db_key, nom, prenom from opti_personne where rtrim(ltrim(upper(common_name))) = '%s'", [CN1], Tuples),
        Tuples = tuple(Res, Nom, Prenom), 	
	Res \= Personne,
	sprintf(Msg, text@msg_probleme_common_name, [Personne@common_name, Personne@nom, Personne@prenom, Nom, Prenom]),
	alert(Msg, [text@ok], _),
	!,
	fail.

%Vérification si une personne est créée et qu'aucun contrat ne lui est encore attribué
personne(_, check(db_before_upload)):-
	not appl_batch_session,
	specific_parameter(jour_check_personne_sans_contrat, on),
	iss_a(Personne, personne),
	Personne@modified = new,
	contrat(_, get_contrats(name, [personne = Personne], Contrats)),
	Contrats = [],
	sprintf(Msg, text@personne_sans_contrat, [Personne@prenom, Personne@nom]),
	alert(Msg, [text@yes, text@no], Reponse),
	Reponse = text@no,
	!,
	fail.

%Vérification si une personne est créée et qu'aucune aptitude ne lui est encore attribuée
personne(_, check(db_before_upload)):-
	not appl_batch_session,
	specific_parameter(jour_check_personne_sans_aptitude, on),
	iss_a(Personne, personne),
	Personne@modified = new,
	personne(Personne, get_aptitudes(name, [], Aptitudes)),
	Aptitudes = [],
	sprintf(Msg, text@personne_sans_aptitude, [Personne@prenom, Personne@nom]),
	alert(Msg, [text@yes, text@no], Reponse),
	Reponse = text@no,
	!,
	fail.

%Vérification si une personne est créée et qu'aucune equipe ne lui est encore attribuée
personne(_, check(db_before_upload)):-
	not appl_batch_session,
	(down_role(administrateur, _) ->
	    % En administrateur 
	    once((specific_parameter(jour_check_personne_sans_equipe, on); specific_parameter(horaire_check_personne_sans_equipe, on)))
	;
	    (mode@mode_planification = '1' ->
		% En module Jour
		specific_parameter(jour_check_personne_sans_equipe, on)
	    ;
		% En module Horaire
		specific_parameter(horaire_check_personne_sans_equipe, on)
	    )
	),
	iss_a(Personne, personne),
	Personne@modified = new,
	all(appart_equipe, name, [ressource = Personne], [], Equipes),
	Equipes = [],
	sprintf(Msg, text@personne_sans_equipe, [Personne@prenom, Personne@nom]),
	alert(Msg, [text@yes, text@no], Reponse),
	Reponse = text@no,
	!,
	fail.

personne(_, check(db_before_upload)).



% Vérifie si le decompte peut s'executer sur la personne en fct du Type de role et du jour J
personne(Personne, can_decompte(Role_Type, DateJ)):-
	!.

% personne(Personne, can_decompte(Role_Type, DateJ)):-
% 	member(Role_Type, [micro_planificateur, macro_planificateur, gestionnaire_micro]),
% 	!.
% personne(Personne, can_decompte(Role_Type, DateJ)):-
% 	not member(Role_Type, [micro_planificateur, macro_planificateur, gestionnaire_micro]),
% 	appl_get_annee_decompte(DateJ, DebutAn, FinAn),
% 	generic_metier_principal(Personne, DebutAn, FinAn, mode@type_ressource),
% 	(specific_parameter(population_decompte, tous) ->
% 	    true
% 	;
% 	    generic_permanent(Personne, DebutAn, FinAn)).	





/*******************************************************************************
* Verifie ou donne les type_ressources et demande_ressources d''une personne
*******************************************************************************/
% A une date J
personne(Personne, aptitude(TypeRessource, DR, Date)):-
	personne(Personne, aptitude(TypeRessource, DR, Date, Date)).


% Qui CHEVAUCHE une période
% Micro planificateur
personne(Personne, aptitude(TypeRessource, DR, From, To)):-
	down_role_in_list(planificateur, [micro_planificateur, gestionnaire_micro]),
	all(type_ressource_direction, type_ressource, [direction = jour_parameter@direction], [], TypeRessourceDir),
	personne(Personne, get_aptitude(name, [], A)),
	(A@demande_ressource)@type_ressource = TypeRessource,
	A@date_debut / 1440 =< To/1440,
	A@date_fin / 1440 >= From/1440,
	instance(TypeRessource),
	$member(TypeRessource, TypeRessourceDir),
	DR = A@demande_ressource.

% Autres Rôles
personne(Personne, aptitude(TypeRessource, DR, From, To)):-
	not down_role_in_list(planificateur, [micro_planificateur, gestionnaire_micro]),
	personne(Personne, get_aptitude(name, [], A)),
	(A@demande_ressource)@type_ressource = TypeRessource,
	A@date_debut / 1440 =< To/1440,
	A@date_fin / 1440 >= From/1440,
	instance(TypeRessource),
	DR = A@demande_ressource.



/*******************************************************************************
* Récupére les aptitudes d''une ressource
*******************************************************************************/
% Micro planificateur
personne(Personne, aptitude(TypeRessource, A, DR, From, To)):-
	down_role_in_list(planificateur, [micro_planificateur, gestionnaire_micro]),
	all(type_ressource_direction, type_ressource, [direction = jour_parameter@direction], [], TypeRessourceDir),
	personne(Personne, get_aptitude(name, [], A)),
	(A@demande_ressource)@type_ressource = TypeRessource,
	A@date_debut / 1440 =< To/1440,
	A@date_fin / 1440 >= From/1440,
	instance(TypeRessource),
	$member(TypeRessource, TypeRessourceDir),
	DR = A@demande_ressource.

% Autres Rôles
personne(Personne, aptitude(TypeRessource, A, DR, From, To)):-
	not down_role_in_list(planificateur, [micro_planificateur, gestionnaire_micro]),
	personne(Personne, get_aptitude(name, [], A)),
	(A@demande_ressource)@type_ressource = TypeRessource,
	A@date_debut / 1440 =< To/1440,
	A@date_fin / 1440 >= From/1440,
	instance(TypeRessource),
	DR = A@demande_ressource.




/*******************************************************************************
*
*******************************************************************************/
% Réussi si une personne appartient en principale à l''équipe chargée
personne(Personne, is_in_equipe_principal(Debut, Fin)):-
	appl_mode_planif(jour),
	personne(Personne, get_equipe_principal(Debut, Fin, [AE|_])),
	AE@equipe_redactionnelle = jour_parameter@equipe_redactionnelle,
	!.
personne(Ressource, is_in_equipe_principal(Debut, Fin)):-
	appl_mode_planif(heure),
	appl_session_give_loading_object(Equipe),
	Equipe@class = equipe_redactionnelle,
	ressource(Ressource, get_equipe_principal(Debut, Fin, AEs)),
	$member(AE, AEs),
	AE@equipe_redactionnelle = Equipe,
	!.

% Réussi si une personne appartient en principale à l''équipe
% Si plusieurs appartenances
personne(Personne, is_in_equipe_principale2(Equipe, Debut, Fin)):-
	personne(Personne, get_equipes_principales_sorted(Debut, Fin, EQPs)),
	EQPs = [EQP|_],
	!,
	EQP@equipe_redactionnelle = Equipe.

% Réussi si une personne appartient en principal au métier chargé (par le planif-ressource)
% Not Planif. Equipe
personne(Personne, is_in_metier_principal(Debut, Fin)):-
	not down_role_in_list(planificateur, [gestionnaire_equipe, equipe]),
	appl_mode_planif(heure),
	!,
	findall(TR, appl_session_give_loading_object(TR), TRs),
	personne(Personne, metier_principal(Debut, Fin, TypeRessource)),
	not not $member(TypeRessource, TRs).

% Réussi si une personne appartient en principal au métier chargé (par le planif-ressource)
% Planif. Equipe
personne(Ressource, is_in_metier_principal(Debut, Fin)):-
	down_role_in_list(planificateur, [gestionnaire_equipe, equipe]),
	!,
	gantt_ressources_get_all_types_ressources(TRs),
	personne(Ressource, metier_principal(Debut, Fin, TypeRessource)),
	not not $member(TypeRessource, TRs).

% Réussi si une personne appartient en secondaire au métier chargé (par le planif-ressource)
% Not Planif. Equipe
personne(Personne, is_in_metier_secondaire(Debut, Fin)):-
	not down_role_in_list(planificateur, [gestionnaire_equipe, equipe]),
	appl_mode_planif(heure),
	!,
	findall(TR, appl_session_give_loading_object(TR), TRs),
	personne(Personne, metier_secondaire(Debut, Fin, TypeRessource)),
	not not $member(TypeRessource, TRs).

% Réussi si une personne appartient en secondaire au métier chargé (par le planif-ressource)
% Planif. Equipe
personne(Ressource, is_in_metier_secondaire(Debut, Fin)):-
	down_role_in_list(planificateur, [gestionnaire_equipe, equipe]),
	!,
	gantt_ressources_get_all_types_ressources(TRs),
	personne(Ressource, metier_secondaire(Debut, Fin, TypeRessource)),
	not not $member(TypeRessource, TRs).


% Récupérer les APPARTENANCE a l''équipe courante d''une personne
% Arité 1
personne(Personne, get_equipe_principal(EQP)):-	
	Date = jour_parameter@jour_j,
	personne(Personne, get_equipe_principal(Date, Date, EQP)).
% Arité 2
personne(Personne, get_equipe_principal(Date, EQP0)):-
	personne(Personne, get_equipe_principal(Date, Date, EQP0)).
% Arité 3
personne(Personne, get_equipe_principal(DateD, DateF, EQP0)):-
	Equipe = jour_parameter@equipe_redactionnelle,
	all(appart_equipe, name, [equipe_redactionnelle = Equipe, ressource = Personne, principal= '1', date_debut =< DateF, date_fin >= DateD], [], EQP),
	EQP \= [],
	!,
	EQP0 = EQP.
personne(Personne, get_equipe_principal(_, _, [])).


% Equipes principales de la personne
personne(Personne, get_equipes_principales_sorted(DateD, DateF, EQP)):-
	all(appart_equipe, name, [ressource = Personne, principal= '1', date_debut =< DateF, date_fin >= DateD], [], EQP0),
	$list_attr_sort(EQP0, EQP, date_debut, db_key).


% Extrait les "trous" de contrat Rq: Intervalles semi_ouverts à droite ..
personne(Personne, get_contrat_holes(From, To, Holes)):-
	personne(Personne, get_contrats(name, [debut =< To, fin >= From], ListContrat)),
	$list_attr_sort(ListContrat, SListContrat, debut, debut),
	personne_extract_contract_holes(SListContrat, From, To, Holes).


	

/*******************************************************************************
* Verification de modification
*******************************************************************************/
personne_check_can_modify(Name, Atts, Flag):-
	not specific_personne_check_can_modify(Name, Atts, Flag),
	!,
	fail.
personne_check_can_modify(Name, Atts, Flag):-
	specific_parameter(personne_common_name_unique, on),
	util_obj_get_value(Name, Atts, common_name, CN),
	personne_cn_normalize(CN, CN1),
	once((
	      iss_a(Item, personne),
	      Item \= Name,
	      personne_cn_normalize(Item@common_name, CN2),
	      CN1 = CN2)),
	!,
	sprintf(Msg, text@frm_check_panel_manager1, [text@common_name]), % Le message pourrait être plus exicite mais conforme au msg du framework
	alert(Msg, [text@abort], Reponse),
	!,
	fail.
personne_check_can_modify(Name, Atts, Flag):-
	util_obj_get_value(Name, Atts, nom, Nom),
	util_obj_get_value(Name, Atts, prenom, Prenom),
	once((
	      iss_a(Item, personne),
	      Item \= Name,
	      Item@nom = Nom,
	      Item@prenom = Prenom
	  )),
	sprintf(Msg, "Une personne nommée %s %s existe déja. Voulez vous continuer?", [Nom, Prenom]),
	alert(Msg, [text@ok, text@no], Reponse),
	Reponse = text@no,
	!,
	fail.
%
personne_check_can_modify(Name, Atts, Flag):-	
	specific_parameter(complition_auto_sortie_societe, on),
	$member(date_sortie_societe <- Date_sortie, Atts),
	personne(Name, check_bad_date_sortie_societe(Date_sortie, Reponse)),
	(Reponse > 1 ->
	    $member(Reponse-Type, [3-'Quota', 2-'Contingent']),
	    sprintf(Msg, text@complition_auto_sortie_societe_msg2, [Type])
	;
	    Msg = text@complition_auto_sortie_societe_msg
	),
	(Reponse > 1 ->
	    alert(Msg, [text@abort], text@abort)
	;
	    alert(Msg, [text@continuer, text@annuler], text@annuler)
	),
	!,
	fail.
personne_check_can_modify(Name, Atts, Flag).


/*******************************************************************************
* Verification de supression
*******************************************************************************/
personne_check_can_destroy(Name, can_destroy):-
	not specific_personne_check_can_destroy(Name, can_destroy),
	!,
	fail.
personne_check_can_destroy(Name, can_destroy).
	
/*******************************************************************************
% personne(+Name, check_bad_date_sortie_societe(+Date_sortie, -Reponse))
* Vérifie si la personne possède un contrat, aptitude et/ou équipe dont la date début est postérieure à 'Date'
* En cas de succès, les valeurs possibles pour 'Reponse' sont 
*        '1' : cas où la supression est possible
*        '2' : cas où au moins un des contrats devant être supprimés est utilisé en base par un contingent
*        '3' : cas où au moins un des contrats devant être supprimés est utilisé en base par un quotat
*
* En cas de 'Reponse = 1', il sera demanée à l''utilisateur s''il veut continuer ou annuler
*******************************************************************************/
personne(Name, check_bad_date_sortie_societe(Date, _)):-
	not specific_parameter(complition_auto_sortie_societe, on),
	!,
	fail.
personne(Name, check_bad_date_sortie_societe(Date, _)):-
	instance(Name),
	Name @ date_sortie_societe =< Date,
	!,
	fail.
personne(Name, check_bad_date_sortie_societe(Date, 2)):-
	instance(Name),
	mu_db_tuple("select 'contrat_'||opti_contrat.db_key, 'contingent_'||opti_contingent.db_key from opti_contingent, opti_contrat 
                                                                 where opti_contingent.contrat = opti_contrat.db_key
							         and opti_contrat.personne = %s", [Name@db_key], Tuple),
	Tuple = tuple(Contrat, Contingent),
	instance(Contrat),
	Contrat@debut > Date,
	not instance(Contingent),
	!.
personne(Name, check_bad_date_sortie_societe(Date, 3)):-
	instance(Name),
	mu_db_tuple("select 'contrat_'||opti_contrat.db_key, 'quota_'||opti_quota.db_key from opti_quota, opti_contrat 
                                                                 where opti_quota.contrat = opti_contrat.db_key
							         and opti_contrat.personne = %s", [Name@db_key], Tuple),
	Tuple = tuple(Contrat, Quota),
	instance(Contrat),
	Contrat@debut > Date,
	not instance(Quota),
	!.

personne(Name, check_bad_date_sortie_societe(Date, 1)):-
	instance(Name),
	is_a(Contrat, contrat),
	Contrat@personne = Name,
	Contrat@debut > Date,
	!.

personne(Name, check_bad_date_sortie_societe(Date, 1)):-
	instance(Name),
	is_a(Aptitude, aptitude),
	Aptitude@ressource = Name, 
	Aptitude@date_debut > Date,
	!.

personne(Name, check_bad_date_sortie_societe(Date, 1)):-
	instance(Name),
	is_a(Appart_equipe, appart_equipe),
	Appart_equipe@ressource = Name, 
	Appart_equipe@date_debut > Date,
	!.

/*******************************************************************************
*
*
*
*                          PANEL MANAGER CALLBACK
*
*
*
*******************************************************************************/
/*******************************************************************************
* Encryptage ou non du password
*******************************************************************************/
personne_panel_manager_mapping_value(fill, personne, Obj, password, Password, Password_Decrypted):-
	specific_parameter(is_user_password_crypted, on),
	!,
	util_sys_decrypt_user_password(Password, Password_Decrypted).
personne_panel_manager_mapping_value(read, personne, Obj, password, Password, Password_Encrypted):-
	specific_parameter(is_user_password_crypted, on),
	!,
	util_sys_encrypt_user_password(Password, Password_Encrypted).
personne_panel_manager_mapping_value(_, personne, Obj, password, Password, Password).


/*******************************************************************************
* Active/Desactive un champ
* + Class
* + Attr
* + active/desactive
*******************************************************************************/
% Passive tous les champs si le feature modifier du tabb frame est passif
personne_panel_manager_attribute_state(personne, si_auth_opti, passive):-
	specific_parameter(personne_disable_si_auth_opti, on),
	!.
personne_panel_manager_attribute_state(personne, Attr, passive):-
	$is_member_of(Attr, [date_dispo_realise_p, date_dispo_realise_r, date_dispo_realise_g, date_validation_realise]),
	!.
personne_panel_manager_attribute_state(personne, Attr, Status):-
	not util_check_if_active_view(obj_page_tabb_frame_personne_personne, edit_modify),
	!,
	Status = passive.
personne_panel_manager_attribute_state(personne, Attr, Status):-
	specific_personne_panel_manager_attribute_state(personne, Attr, Status),
	!.
personne_panel_manager_attribute_state(personne, Attr, passive):-
	panel_manager(personne, current(si_preference_h, Flag)),
	Flag = '0',
	$member(Attr, [si_lundi, si_mardi, si_mercredi, si_jeudi, si_vendredi, si_samedi, si_dimanche,
                       lundi_heure_debut, mardi_heure_debut, mercredi_heure_debut, jeudi_heure_debut, vendredi_heure_debut, samedi_heure_debut, dimanche_heure_debut,
		       lundi_heure_fin, mardi_heure_fin, mercredi_heure_fin, jeudi_heure_fin, vendredi_heure_fin, samedi_heure_fin, dimanche_heure_fin]).
personne_panel_manager_attribute_state(personne, Attr, passive):-
	panel_manager(personne, current(si_preference_h, Flag)),
	Flag \= '0',
	panel_manager(personne, current(si_lundi, Attr_Flag)),
	Attr_Flag = '0',
	$member(Attr, [lundi_heure_debut, lundi_heure_fin]).
personne_panel_manager_attribute_state(personne, Attr, passive):-
	panel_manager(personne, current(si_preference_h, Flag)),
	Flag \= '0',
	panel_manager(personne, current(si_mardi, Attr_Flag)),
	Attr_Flag = '0',
	$member(Attr, [mardi_heure_debut, mardi_heure_fin]).
personne_panel_manager_attribute_state(personne, Attr, passive):-
	panel_manager(personne, current(si_preference_h, Flag)),
	Flag \= '0',
	panel_manager(personne, current(si_mercredi, Attr_Flag)),
	Attr_Flag = '0',
	$member(Attr, [mercredi_heure_debut, mercredi_heure_fin]).
personne_panel_manager_attribute_state(personne, Attr, passive):-
	panel_manager(personne, current(si_preference_h, Flag)),
	Flag \= '0',
	panel_manager(personne, current(si_jeudi, Attr_Flag)),
	Attr_Flag = '0',
	$member(Attr, [jeudi_heure_debut, jeudi_heure_fin]).
personne_panel_manager_attribute_state(personne, Attr, passive):-
	panel_manager(personne, current(si_preference_h, Flag)),
	Flag \= '0',
	panel_manager(personne, current(si_vendredi, Attr_Flag)),
	Attr_Flag = '0',
	$member(Attr, [vendredi_heure_debut, vendredi_heure_fin]).
personne_panel_manager_attribute_state(personne, Attr, passive):-
	panel_manager(personne, current(si_preference_h, Flag)),
	Flag \= '0',
	panel_manager(personne, current(si_samedi, Attr_Flag)),
	Attr_Flag = '0',
	$member(Attr, [samedi_heure_debut, samedi_heure_fin]).
personne_panel_manager_attribute_state(personne, Attr, passive):-
	panel_manager(personne, current(si_preference_h, Flag)),
	Flag \= '0',
	panel_manager(personne, current(si_dimanche, Attr_Flag)),
	Attr_Flag = '0',
	$member(Attr, [dimanche_heure_debut, dimanche_heure_fin]).
% Passive les champs de la démat si non active
personne_panel_manager_attribute_state(personne, Attr, passive):-
	not specific_parameter(mission_si_dematerialisation, on),
	$member(Attr, [si_non_dematerialisation, si_email1_demat, si_email2_demat, si_email3_demat,
	               si_telephone1_demat, si_telephone2_demat, si_telephone3_demat]).
personne_panel_manager_attribute_state(personne, 0, passive):-
	!.





/*******************************************************************************
* Callback appelé avant le remplissage du panel
*******************************************************************************/
personne_panel_manager_before_fill(personne):-
	specific_personne_panel_manager_before_fill(personne),
	fail.
personne_panel_manager_before_fill(personne).


/*******************************************************************************
* Callback appelé avant l''ouverture du panel
*******************************************************************************/
personne_panel_manager_before_open(personne):-
	specific_personne_panel_manager_before_open(personne),
	fail.
personne_panel_manager_before_open(personne):-
	% Affiche ou non les mot de passe des personnes selon le rôle
	instance(mode@role),
	not (mode@role)@show_password = '1',
	panel_manager(personne, show(password, off)),
	button(personne_authentification_show_password, unmap),
	fail.	
personne_panel_manager_before_open(personne):-
	panel_manager(personne, current_state(create)),
	instance(mode@role),
	(mode@role)@show_password = '1',
	specific_parameter(initialise_password, on),
	util_random_string(8, Random_String),
	panel_manager(personne, select(password, Random_String)),
	button(personne_authentification_show_password, open),
	fail.
personne_panel_manager_before_open(personne):-
	panel_manager(personne, current(si_auth_opti, Value)),
	member(Value-Flag-Label, ['1'-active-text@login, '0'-passive-text@common_name]),
	panel_manager(personne, status(password, Flag)),
	panel_manager(personne, label(common_name, Label)),
	button(personne_authentification_show_password, Flag),
	fail.
personne_panel_manager_before_open(personne):-
	setval(personne_show_password_pressed, 0),
	text2(personne_authentification_password_view, unmap),
	fail.
personne_panel_manager_before_open(personne):-
	!.

/*******************************************************************************
* Callback d''ouverture du panel
*******************************************************************************/
personne_panel_manager_check_arglist(personne, create, Name, Arglist):-
	personne(Name, check(can_create(Arglist))),
	!.
personne_panel_manager_check_arglist(personne, modify, Name, Arglist):-
	personne(Name, check(can_modify(Arglist))),
	!.


/*******************************************************************************
* Callback dynamic de saisie
*******************************************************************************/
% Initalise le champ common name au changement du nom ou prenom
personne_panel_manager_item_check_callback(personne, Attr, Object, Value):-
	specific_personne_panel_manager_item_check_callback(personne, Attr, Object, Value),
	!.
% 
personne_panel_manager_item_check_callback(personne, nom, Object, Nom):-
	panel_manager(personne, current_state(create)),
	panel_manager(personne, current(prenom, Prenom)),
	util_substr(Nom, 1, 6, Nom1),
	util_substr(Prenom, 1, 1, Prenom1),
	sprintf(Common_Name0, "%s%s", [Nom1, Prenom1]),
	personne_get_common_name(Common_Name0, Common_Name1),
	panel_manager(personne, select(common_name, Common_Name1)),
	!.
personne_panel_manager_item_check_callback(personne, prenom, Object, Prenom):-
	panel_manager(personne, current_state(create)),
	panel_manager(personne, current(nom, Nom)),
	util_substr(Nom, 1, 6, Nom1),
	util_substr(Prenom, 1, 1, Prenom1),
	sprintf(Common_Name0, "%s%s", [Nom1, Prenom1]),
	personne_get_common_name(Common_Name0, Common_Name1),
	panel_manager(personne, select(common_name, Common_Name1)),
	!.
personne_panel_manager_item_check_callback(personne, si_preference_h, Object, Flag):-
	% Active ou passive les champs concernant les préférences jours
	personne_si_preference_h_days([si_lundi, si_mardi, si_mercredi, si_jeudi, si_vendredi, si_samedi, si_dimanche], Flag),
	!.
personne_panel_manager_item_check_callback(personne, Attr, Object, Flag):-
	% Active ou passive les champs concernant le jour en question 
	$is_member_of(Attr, [si_lundi, si_mardi, si_mercredi, si_jeudi, si_vendredi, si_samedi, si_dimanche]),
	$member(Flag-Action, ['0'-passive, '1'-active]),
	personne_si_preference_h_horaires(Attr, Flag, Action),
	!.

% Gestion des switch démat comme des radios
personne_panel_manager_item_check_callback(personne, Attr, Object, Flag):-
	$member(Attr-Attr2-Attr3, [si_email1_demat-si_email2_demat-si_email3_demat,
	                           si_email2_demat-si_email3_demat-si_email1_demat,
	                           si_email3_demat-si_email1_demat-si_email2_demat,
	                           si_telephone1_demat-si_telephone2_demat-si_telephone3_demat,
	                           si_telephone2_demat-si_telephone3_demat-si_telephone1_demat,
	                           si_telephone3_demat-si_telephone1_demat-si_telephone2_demat]),
	Flag = '1',
	panel_manager(personne, select(Attr2, off)),
	panel_manager(personne, select(Attr3, off)),
	fail.
% Si authentification OPTI
personne_panel_manager_item_check_callback(personne, si_auth_opti, Object, Value):-
	member(Value-Flag-Label, ['1'-active-text@login, '0'-passive-text@common_name]),
	panel_manager(personne, status(password, Flag)),
	panel_manager(personne, label(common_name, Label)),
	button(personne_authentification_show_password, Flag),
	text2(personne_authentification_password_view, Flag),
	fail.

personne_panel_manager_item_check_callback(personne, Attr, Object, Value):-
	!.



personne_get_common_name(Common_Name, Common_Name):-
	not specific_parameter(personne_common_name_unique, on),
	!.
personne_get_common_name(Common_Name, Common_Name):-
	specific_parameter(personne_common_name_unique, on),
	all(personne, common_name, [], [], Common_Names),
	not $member(Common_Name, Common_Names),
	!.
personne_get_common_name(Common_Name0, Common_Name):-
	specific_parameter(personne_common_name_unique, on),
	setval($personne_common_name, 0),
	personne_get_common_name_lp(Common_Name0, Common_Name),
	!.

% Increment avec une valeur integer si redundance
personne_get_common_name_lp(Common_Name, Common_Name1):-
	incval($personne_common_name, Value),
	sprintf(Common_Name1, "%s%d", [Common_Name, Value]),
	all(personne, common_name, [], [], Common_Names),
	not $member(Common_Name1, Common_Names),
	!.
personne_get_common_name_lp(Common_Name, Common_Name1):-
	!,
	personne_get_common_name_lp(Common_Name, Common_Name1).



/*******************************************************************************
* Permet à l'utilisateur d'interdire des touches particulières
*******************************************************************************/
personne_key_callback(Name, Item, Type, Mode, Key):-
	specific_personne_key_callback(Name, Item, Type, Mode, Key),
	!.




/*******************************************************************************
* Callback du bouton pour visualiser les mots de passe
*******************************************************************************/
personne_show_password_pressed(authentification, personne_authentification_show_password):-
	incval(personne_show_password_pressed, 1),
	panel_manager(personne, current(password, Pwd)),
	text2(personne_authentification_password_view, select(Pwd)),
	text2(personne_authentification_password_view, open).
personne_show_password_pressed(authentification, personne_authentification_show_password):-
	setval(personne_show_password_pressed, 0),
	text2(personne_authentification_password_view, select('')),
	text2(personne_authentification_password_view, unmap).


/*******************************************************************************
* Callback du mdp visible : Le recopie dans le mdp masqué
*******************************************************************************/
personne_authentification_password_view_edit(authentification, personne_authentification_password_view, New_Pwd):-
	panel_manager(personne, select(password, New_Pwd)).




/*******************************************************************************
*
*******************************************************************************/
% Active ou passive les champs concernant les préférences jours
personne_si_preference_h_days(Days, Flag):-
	$member(Flag-Switch-Action, ['0'-off-passive, '1'-on-active]),
	!,
	anyway((
	    $member(Attr, Days),
	    % Pas d''intialisation / re-initialisation
	    %panel_manager(personne, select(Attr, Switch)),
	    panel_manager(personne, status(Attr, Action)),
	    % If si_preference_h = off or si_%jour% = off
	    ((Action = passive  ; panel_manager(personne, current(Attr, State)), State = '1') ->
		personne_si_preference_h_horaires(Attr, Flag, Action)
	    ;
		true
	    ),
	    fail
	)).

% Active ou passive les champs concernant le jour en question Ex: Attr = si_lundi, Flag = '0' ou '1', Action = passive ou active
personne_si_preference_h_horaires(Attr, Flag, Action):-
	!,
	personne_si_preference_h_get_debut_fin_attr(Attr, Attr_Debut, Attr_Fin),
	% Pas d''intialisation / re-initialisation
	%personne_si_preference_h_horaires_init(Flag, Attr_Debut, Attr_Fin),
	panel_manager(personne, status(Attr_Debut, Action)),
	panel_manager(personne, status(Attr_Fin, Action)).

% Si flag est '0' / mise à jour à la valeur par défaut
personne_si_preference_h_horaires_init('0', Attr_Debut, Attr_Fin):-
	!,
	panel_manager(personne, select(Attr_Debut, 0)),
	panel_manager(personne, select(Attr_Fin, 1440)).
personne_si_preference_h_horaires_init(_, _, _).

% Obtien les attrs de debut et fin d''un jour donné
personne_si_preference_h_get_debut_fin_attr(Attr, Attr_Debut, Attr_Fin):-
	!,
	util_substr(Attr, 4, Day),
	sprintf(Attr_Debut, "%s_heure_debut", [Day]),
 	sprintf(Attr_Fin, "%s_heure_fin", [Day]).


/*******************************************************************************
* Table des attributs par rapport au numéro du jour dans la semaine
*******************************************************************************/
personne_si_preference_h_weekno_attrs(0, si_lundi, lundi_heure_debut, lundi_heure_fin).
personne_si_preference_h_weekno_attrs(1, si_mardi, mardi_heure_debut, mardi_heure_fin).
personne_si_preference_h_weekno_attrs(2, si_mercredi, mercredi_heure_debut, mercredi_heure_fin).
personne_si_preference_h_weekno_attrs(3, si_jeudi, jeudi_heure_debut, jeudi_heure_fin).
personne_si_preference_h_weekno_attrs(4, si_vendredi, vendredi_heure_debut, vendredi_heure_fin).
personne_si_preference_h_weekno_attrs(5, si_samedi, samedi_heure_debut, samedi_heure_fin).
personne_si_preference_h_weekno_attrs(6, si_dimanche, dimanche_heure_debut, dimanche_heure_fin).




/*******************************************************************************
* Heures de préférences pour une journée donnée
% Attention : Echoue si personne sans préférences
*******************************************************************************/
personne(Name, get_heures_preferences(Date, Date_Debut, Date_Fin)):-
	julian_date_day_of_week(Date, WeekDay),
	personne_si_preference_h_weekno_attrs(WeekDay, Attr, Attr_Heure_Debut, Attr_Heure_Fin),
	Name@Attr = '1',
	!,
	Heure_Debut = Name@Attr_Heure_Debut,
	Heure_Fin0 = Name@Attr_Heure_Fin,
	
	% Si heure de fin = 24h00, récupère la bonne heure de fin du lendemain
	(Heure_Fin0 >= 1440 ->
	    Lendemain is Date + 1440,
	    julian_date_day_of_week(Lendemain, Lendemain_WeekDay),
	    personne_si_preference_h_weekno_attrs(Lendemain_WeekDay, Lendemain_Attr, Lendemain_Attr_Heure_Debut, Lendemain_Attr_Heure_Fin),
	    (Name@Lendemain_Attr = '1', Name@Lendemain_Attr_Heure_Debut = 0 ->
		% Préférence le lendemain et heure début à 0h : on prend l'heure de fin comme référence
		Heure_Fin is max(1440 + Name@Lendemain_Attr_Heure_Fin, Heure_Fin0)
	    ;
		% Sinon, heure de fin du jour courant
		Heure_Fin = Heure_Fin0
	    )
	;
	    Heure_Fin = Heure_Fin0
	),
	
	Date_Debut is Date + Heure_Debut,
	Date_Fin is Date + Heure_Fin.
personne(Name, get_heures_preferences(Date, Date, Date)).




/*******************************************************************************
* Fermeture du panel
*******************************************************************************/
personne_panel_manager_closed(personne, Obj):-
	specific_personne_panel_manager_closed(personne, Obj),
	fail.
personne_panel_manager_closed(personne, Obj).




/*******************************************************************************
* Callback global de changement
*******************************************************************************/
personne_panel_manager_object_changed(personne, Name):-
	!.


/*******************************************************************************
* Callbacks de changement (creation/modification)
*******************************************************************************/	
personne_panel_manager_object_changed(personne, Name, Arglist, OldArglist):-
	specific_parameter(complition_auto_sortie_societe, on),
	$member(date_sortie_societe <- New_date, Arglist),
	$member(date_sortie_societe <- Old_date, OldArglist),
	New_date < Old_date,
	contrat(_, get_contrats(name, [personne = Name, fin > New_date], Contrats)),
	Contrats \= [],
	$member(Contrat, Contrats),
	(Contrat@debut < New_date ->
	    contrat(Contrat, set_atts([fin <- New_date])),
	    tabb_frame(_, redraw_entry(Contrat))
	;
	    tabb_frame(_, delete(Contrat)),
	    contrat(Contrat, destroy)
	),
	fail.
personne_panel_manager_object_changed(personne, Name, Arglist, OldArglist):-
	specific_parameter(complition_auto_sortie_societe, on),
	$member(date_sortie_societe <- New_date, Arglist),
	$member(date_sortie_societe <- Old_date, OldArglist),
	New_date < Old_date,
	aptitude(_, get_aptitudes(name, [ressource = Name, date_fin > New_date], Aptitudes)),
	Aptitudes \= [],
	$member(Aptitude, Aptitudes),
	(Aptitude@date_debut < New_date ->
	    aptitude(Aptitude, set_atts([date_fin <- New_date])),
	    tabb_frame(_, redraw_entry(Aptitude))
	;
	    tabb_frame(_, delete(Aptitude)),
	    aptitude(Aptitude, destroy)
	),
	fail.
personne_panel_manager_object_changed(personne, Name, Arglist, OldArglist):-
	specific_parameter(complition_auto_sortie_societe, on),
	$member(date_sortie_societe <- New_date, Arglist),
	$member(date_sortie_societe <- Old_date, OldArglist),
	New_date < Old_date,
	all(appart_equipe, name, [ressource = Name, date_fin > New_date], [], Equipes),
	Equipes \= [],
	$member(Equipe, Equipes),
	(Equipe@date_debut < New_date ->
	    appart_equipe(Equipe, set_atts([date_fin <- New_date])),
	    tabb_frame(_, redraw_entry(Equipe))
	;
	    tabb_frame(_, delete(Equipe)),
	    appart_equipe(Equipe, destroy)
	),
	fail.
personne_panel_manager_object_changed(personne, Name, Arglist, OldArglist):-
	specific_personne_panel_manager_object_changed(personne, Name, Arglist, OldArglist),
	fail.
personne_panel_manager_object_changed(personne, Name, Arglist, OldArglist):-
	!.



/*******************************************************************************
*regroupe les personnes qui ont un contrat et qui n''ont pas
*******************************************************************************/
personne_get_gr_contrat([], [], []).
personne_get_gr_contrat([Personne|Reste], [Personne|Reste2], Reste3):-
	instance(Personne@contrat),
	!,
	personne_get_gr_contrat(Reste, Reste2, Reste3).
personne_get_gr_contrat([Personne|Reste], Reste2, [Personne|Reste3]):-
	personne_get_gr_contrat(Reste, Reste2, Reste3). 


/*******************************************************************************
* Regroupe les personnes permamants/non permamant/ pas de contrat
*******************************************************************************/
personne_get_gr_contrat([], [], [], []).
personne_get_gr_contrat([Personne|Reste], [Personne|Reste2], Reste3, Reste4):-
	instance(Personne@contrat),
	((Personne@contrat)@type_contrat)@si_permanent == '1',
	!,
	personne_get_gr_contrat(Reste, Reste2, Reste3, Reste4).
personne_get_gr_contrat([Personne|Reste], Reste2, [Personne|Reste3], Reste4):-
	instance(Personne@contrat),	
	!,
	personne_get_gr_contrat(Reste, Reste2, Reste3, Reste4).
personne_get_gr_contrat([Personne|Reste], Reste2, Reste3, [Personne|Reste4]):-
	personne_get_gr_contrat(Reste, Reste2, Reste3, Reste4).

	

/*******************************************************************************
*  Donne les personnes qui ont une 'indispo, etiquette, doubure, marqueur' sur la période de visualisation

*******************************************************************************/
personne_get_personne_objet_in_period([], From, To, [], []).
personne_get_personne_objet_in_period([Personne|PersonnesNonPermanent], From, To, [Personne|Reste], NP):-
	mode@view \= vue_journaliste_tableau_service,
	% Cas 1 : On a forcé la personne a etre présent dans le Gantt
	(Personne@present_in_cdd_gantt == 1
    ;
    	% Cas 2 : C'est une personne sur laquelle il existe déjà un planning	    
	member(Class-Ressource-Debut-Fin, [etiquette-personne-jour_planif-jour_planif,
	                                   doublure_etiquette-personne-jour_planif-jour_planif,
	                                   indispo_planif-ressource-date_debut-date_fin,
				           marqueur-ressource-date-date_to]),
	once((
	iss_a(Objet,Class),
	Objet@Ressource == Personne,
	Objet@Debut/1440 =< To/1440,
	Objet@Fin/1440 >= From/1440
	))),
	%PC: Ce prédicat étant utilisé à de nombreux endroits, ne pas marquer dedans les personnes
%	Personne@present_in_cdd_gantt <- 1,
	!,
	personne_get_personne_objet_in_period(PersonnesNonPermanent, From, To, Reste, NP).
personne_get_personne_objet_in_period([Personne|PersonnesNonPermanent], From, To, Reste, [Personne|NP]):-
	personne_get_personne_objet_in_period(PersonnesNonPermanent, From, To, Reste, NP).



/*******************************************************************************
* Extrait les "trous" de contrat Rq: Intervalles semi_ouverts à droite ..
*******************************************************************************/
personne_extract_contract_holes(ListContrat, From, To, []):-
	From > To,
	!.
%end contract missing
personne_extract_contract_holes([], From, To, [From-To]).

personne_extract_contract_holes([Contract|LC], From, To, [From-Contract@start|Holes]):-
	Contract@debut > From,
	!,
	personne_extract_contract_holes([Contract|LC], Contract@start, To, Holes).
	
personne_extract_contract_holes([Contract|LC], From, To, Holes):-
	%Contract@start =< From,
	From1 is (Contract@fin/1440 +1)*1440,
	personne_extract_contract_holes(LC, From1, To, Holes).










/*******************************************************************************
*
*
*
*                GESTION DES CYCLES
*
*
*
*******************************************************************************/
/*******************************************************************************
* Renvoie l''équipe cyclique à laquelle appartient la personne à une date donnée
* TV20111220 : Renvoie en priorité l''équipe principale de la personne (avant on renvoyait dans n''importe quel ordre)
*******************************************************************************/
% Arité 2
personne(Name, get_equipe_cycle(Date, Equipe_cycle)):-
	personne(Name, get_equipe_cycle(Date, _, Equipe_cycle)).

% Arité 3
personne(Name, get_equipe_cycle(Date, Appart, Equipe_cycle)):-
	$canevas_attr(mode@mode_planification, Class_Appart_Equipe_Cycle, Attr_Equipe_Cycle, Class_Roulement, Class_Canevas, Class_Ligne_Canevas, Attr_Numero_Ligne, Attr_Res),

	all(Class_Appart_Equipe_Cycle, name, [Attr_Res = Name, date_debut =< Date, date_fin >= Date], [], Apparts),

	% En module jour, on vérifie que la personne appartient à l'équipe rédactionnelle de l'équipe cyclique
	(mode@mode_planification = '1' ->
	    all(appart_equipe, name, [ressource = Name, date_debut =< Date, date_fin >= Date], [], Apparts_Equipe_Red)
	;
	    % En module horaire, il faudrait vérifier les aptitudes
	    true
	),

	$list_attr_sort(Apparts, Appart_Sorted, principal, nom),
	% Reverse pour avoir principal = '1' en premier
	util_reverse(Appart_Sorted, Apparts_SR),
	$member(Appart, Apparts_SR),

	% En module jour, on vérifie que la personne appartient à l'équipe rédactionnelle de l'équipe cyclique
	(mode@mode_planification = '1' ->
	    once(($member(Appart_Equipe_Red, Apparts_Equipe_Red),
	          (Appart@Attr_Equipe_Cycle)@equipe_redactionnelle = Appart_Equipe_Red@equipe_redactionnelle))
	;
	    % En module horaire, il faudrait vérifier les aptitudes 
	    true
	),
	Equipe_cycle = Appart@Attr_Equipe_Cycle.


/*******************************************************************************
* Renvoie le canevas auquel appartient la personne à une date donnée
*******************************************************************************/
personne(Name, get_canevas(Date, Canevas)):-
	personne(Name, get_equipe_canevas(Date, _, _, Canevas, _, _)).


/*******************************************************************************
* Renvoie le canevas auquel appartient la personne à une date donnée
* Ainsi qu''un flag '0' ou '1' s''il y a rotation ou non
*******************************************************************************/
personne(Name, get_canevas(Date, Canevas, Flag)):-
	personne(Name, get_equipe_canevas(Date, _, _, Canevas, _, Flag)).


/*******************************************************************************
* Renvoie l''équipe et le canevas auquel appartient la personne à une date donnée
*******************************************************************************/
personne(Name, get_equipe_canevas(Date, Appart, Equipe_cycle, Canevas, Flag)):-
	personne(Name, get_equipe_canevas(Date, Appart, Equipe_cycle, Canevas, R, Flag)).


/*******************************************************************************
* Renvoie l''équipe et le canevas auquel appartient la personne à une date donnée
*******************************************************************************/
% LA RESSOURCE EST INSTANCIEE DANS LE ROULEMENT
personne(Name, get_equipe_canevas(Date, Appart, Equipe_cycle, Canevas, R, Flag)):-
	$canevas_attr(mode@mode_planification, Class_Appart_Equipe_Cycle, Attr_Equipe_Cycle, Class_Roulement, Class_Canevas, Class_Ligne_Canevas, Attr_Numero_Ligne, Attr_Res),
	personne(Name, get_equipe_cycle(Date, Appart, Equipe_cycle)),
	iss_a(R, Class_Roulement),
	R@date_debut =< Date,
	R@date_fin >= Date,
	R@Attr_Equipe_Cycle = Equipe_cycle,
	R@ressource = Name,
	!,
	Canevas = R@Class_Canevas,
	Flag = R@si_rotation.
% LA RESSOURCE N'EST PAS INSTANCIEE DANS LE ROULEMENT (ANCIEN MODE DE DEROULEMENT / DEROULEMENT SUR UNE RESSOURCE NON-INSTANCIEE
personne(Name, get_equipe_canevas(Date, Appart, Equipe_cycle, Canevas, R, Flag)):-
	$canevas_attr(mode@mode_planification, Class_Appart_Equipe_Cycle, Attr_Equipe_Cycle, Class_Roulement, Class_Canevas, Class_Ligne_Canevas, Attr_Numero_Ligne, Attr_Res),
	personne(Name, get_equipe_cycle(Date, Appart, Equipe_cycle)),
	iss_a(R, Class_Roulement),
	R@date_debut =< Date,
	R@date_fin >= Date,
	R@Attr_Equipe_Cycle = Equipe_cycle,
	not instance(R@ressource),
	!,
	Canevas = R@Class_Canevas,
	Flag = R@si_rotation.


/*******************************************************************************
* Renvoie l''équipe, l''appart equipe, le canevas, le roulement, le flag si rotation et la ligne de cycle
* sur laquelle est une personne à une date donnée
*******************************************************************************/
personne(Name, get_equipe_canevas(Date, Appart, Equipe_cycle, Canevas, R, Flag, Ligne)):-
	personne(Name, get_equipe_canevas(Date, Appart, Equipe_cycle, Canevas, R, Flag)),
	$canevas_attr(mode@mode_planification, Class_Appart_Equipe_Cycle, Attr_Equipe_Cycle, Class_Roulement, Class_Canevas, Class_Ligne_Canevas, Attr_Numero_Ligne, Attr_Res),
	(instance(R@ressource) ->
	    all(Class_Ligne_Canevas, name, [Class_Canevas = Canevas, numero = R@numero_ligne], [], LCs_E),
	    LCs_E = [Ligne|_]
	;
	    (Flag = '1'  ->
      	        % Si c'est un cycle avec roulement, alors on calcul la position de la personne à la Date donnée
		all(Class_Ligne_Canevas, name, [Class_Canevas = Canevas], [], LCs_E),
	        % trie les lignes selon leur n°
	        % Attention : Attr_Numero_Ligne = Attr de l''appart equipe cycle et non pas de ligne canevas
		$list_attr_sort(LCs_E, LCs_Sorted, numero, numero),
%	        msort(LCs_E, LCs_Sorted),

	        % Se calle sur la bonne ligne
		No_Ligne is Appart@Attr_Numero_Ligne - 1,
		util_cycle(LCs_Sorted, No_Ligne, LCs_Sorted2),

	        % Applique une rotation
		Nb_Rotations is R@numero_ligne,
		util_cycle(LCs_Sorted2, Nb_Rotations, [Ligne|_])
	    
	    ;
	        % Si c'est un cycle sans roulement, alors la ligne correspond à la position de la personne dans son équipe
		all(Class_Ligne_Canevas, name, [Class_Canevas = Canevas, numero = Appart@Attr_Numero_Ligne], [], LCs),
		LCs = [Ligne]
	    )
	).

/*******************************************************************************
* Recupere la periode du cycle
* Regle: 
*  une date donnée D, le compteur cyclique associé aux personnes est calculé de la façon suivante :
*     Cas 1 : Le déroulement s''est fait avec rotation des lignes
*             On récupère l''objet roulement_cycle correspondant à la ligne 1 du déroulement du canevas (numero_ligne=0 dans le code)
*             On effectue le calcul sur la période allant de roulement_cycle@date_debut à roulement_cycle@date_debut + Amplitude canevas * Nb Lignes
*             La coloration du compteur est définie en fonction du total de temps travaillé sur le canevas : somme des temps de travail par ligne
*
*
*     Cas 2 : Le déroulement s''est fait sans rotation des lignes
*             On récupère l''objet roulement_cycle existant à la date D
*             On effectue le calcul sur la période de roulement_cycle@date_debut à roulement_cycle@date_fin
*             La coloration du compteur est définie en fonction du total de temps travaillé sur la ligne 
*             associée à la personne : N° ligne de la personne dans l''équipe + N° 
*             de ligne du roulement_cycle (modulo le nombre de lignes du cycle)
*
*******************************************************************************/
personne(Name, get_periode_cycle(Date, From, To)):-
	personne(Name, get_canevas(Date, Canevas, Flag)),
	% verifier si canevas est instancié
	instance(Canevas),
	$canevas_attr(mode@mode_planification, Class_Appart_Equipe_Cycle, Attr_Equipe_Cycle, Class_Roulement, Class_Canevas, Class_Ligne_Canevas, Attr_Numero_Ligne, Attr_Res),
	(((Flag = '1', not specific_parameter(compteur_cycle, ignore_rotation))) ->
	    % Récupère le premier roulement correspondant à la ligne 1 avant la date Date	    
	    iss_a(Roulement, Class_Roulement),
	    Roulement@Class_Canevas = Canevas,
	    Roulement@ressource = Name,
	    Roulement@numero_ligne_init = 1,
	    From is Roulement@date_debut,
	    To is From + Canevas@longueur * Canevas@nb_lignes * 1440 - 1440,
	    From =< Date,
	    To >= Date
	;
	    iss_a(Roulement, Class_Roulement),
	    Roulement@Class_Canevas = Canevas,
	    Roulement@ressource = Name,
	    
	    From = Roulement@date_debut,
	    To = Roulement@date_fin,
	    
	    From =< Date,
	    To >= Date
	),
	!.

% point de choix pour un roulement avec rotation n''ayant pas la 1ère ligne de l''équipe de cycle de déroulé sur la période du cycle
personne(Name, get_periode_cycle(Date, From, To)):-
%$logc	personne(Name, get_canevas(Date, Canevas, Flag)),
	% verifier si canevas est instancié
%	instance(Canevas),
	$canevas_attr(mode@mode_planification, Class_Appart_Equipe_Cycle, Attr_Equipe_Cycle, Class_Roulement, Class_Canevas, Class_Ligne_Canevas, Attr_Numero_Ligne, Attr_Res),
	not specific_parameter(compteur_cycle, ignore_rotation),
	% Récupère un roulement correspondant à la date Date	    
	iss_a(Roulement, Class_Roulement),
%	Roulement@Class_Canevas = Canevas,
	Roulement@ressource = Name,
	Roulement@date_debut =< Date,
	Roulement@date_fin >= Date,
	Roulement@si_rotation = '1',
	Canevas = Roulement@Class_Canevas,
	instance(Roulement@Attr_Equipe_Cycle),
	!,
	% A partir du roulement courant retrouve le 1er jour de déroulement théorique
	% Ex: From_Theo is 13047840 - 7 * (9-1) * 1440 (résult 28/08 pour le 23/10)
	From_Theo is Roulement@date_debut - Canevas@longueur * (Roulement@numero_ligne_init-1) * 1440,
	To_Theo is From_Theo + Canevas@longueur * Canevas@nb_lignes * 1440 - 1440,
% 	writeln(From_Theo-Canevas@longueur - Canevas@nb_lignes ),
% 	mu_dates([From_Theo, To_Theo]),
	all(Class_Roulement, name, [ressource = Name, Attr_Equipe_Cycle = Roulement@Attr_Equipe_Cycle, date_debut >= From_Theo, date_fin =< To_Theo], [], Rs),
	$list_attr_sort(Rs, Rs_Sorted, date_debut, date_fin),
	Rs_Sorted = [R_First|_],
	util_reverse(Rs_Sorted, Rs_Sorted_Reversed),
	Rs_Sorted_Reversed = [R_Last|_],
	From is R_First@date_debut,
	To is R_Last@date_fin.



/*******************************************************************************
* Récupère la durée du cycle selon les roulements sur une personne (Durée prévisionnelle)
*******************************************************************************/
personne(Personne, get_duree_periode_cycle(Debut, Fin, Duree)):-
	personne(Personne, get_activites_periode_cycle(Debut, Fin, Activites_Cycle)),
	findall(Duree_A, ($member(Act_canevas, Activites_Cycle), generic_get_duree(Act_canevas, Duree_A)), Durees),
	util_obj_sum_rat(Durees, Duree),
	!.
	
	
	
/*******************************************************************************
* Récupère les activités canevas pour une période pour une personne (Activités prévisionnelle)
*******************************************************************************/
personne(Personne, get_activites_periode_cycle(Debut, Fin, Activites_Cycle)):-
	$canevas_attr(mode@mode_planification, _, _, Class_Roulement, _, _, _, _),
	all(Class_Roulement, name, [date_debut =< Fin, date_fin >= Debut, ressource = Personne], [], Roulements),
	Call =.. [Class_Roulement, _, get_activites(Debut, Fin, Roulements, Activites_Cycle)],
	call(Call),
	!.
personne(Personne, get_activites_periode_cycle(Debut, Fin, [])).


/*******************************************************************************
* Société de la personne à la date donnée
*******************************************************************************/
personne(Personne, get_societes(Date, Societes)):-
	all(appart_societe, societe, [ressource = Personne, date_debut =< Date, date_fin >= Date], [], Societes).
	

/*******************************************************************************
* Récupère le planning d''une personne (Trié)
*******************************************************************************/
personne(Personne, get_planning_sorted(PS)):-
	ressource(Personne, get_planning_sorted(PS)).


/*******************************************************************************
* Récupère le planning d''une personne 
*******************************************************************************/
personne(Personne, get_planning(PS)):-
	ressource(Personne, get_planning(PS)).


/*******************************************************************************
* Regarde si la personne possède une dispo entre deux dates
*******************************************************************************/
personne(Personne, has_dispo(Debut_W, Fin_W, Duration)):-
	ressource(Personne, has_dispo(Debut_W, Fin_W, Duration)).



/*******************************************************************************
* En fonction du module (technicien ou journaliste), renvoie les attributs utilisés
* sur les canevas
% $canevas_attr('0'/'1', Class_Appart_Equipe_Cycle, Attr_Equipe_Cycle, Class_Roulement, Attr_Canevas, Class_Ligne_Canevas, Attr_Numero_Ligne, Attr_Res)
*******************************************************************************/
% Techniciens
$canevas_attr('0', appart_cycle_t, equipe_cycle_t, roulement_cycle_t, canevas_t, ligne_canevas_t, numero, personne).

% Journaliste
$canevas_attr('1', appart_equipe_cycle, equipe_cycle, roulement_cycle, canevas, ligne_canevas, numero_ligne_init, ressource).





/*******************************************************************************
* Responsables RH
*   personne(+Personne, get_responsables_rh(-Responsables, +From, +To))
*******************************************************************************/
personne(Personne, get_responsables_rh(Responsables, From, To)):-
	findall(Responsable, (is_a(Responsable, responsable_rh), 
	                      vue_personne_responsable_rh(Responsable, Personne, DD, DF), 
			      DD =< To, DF >= From), 
	        Responsables0),
	util_distinct(Responsables0, Responsables).



/*******************************************************************************
* Vérifie qu'une personne possède au moins un responsable RH
*******************************************************************************/
personne(Personne, has_responsable_rh(From, To)):-
	vue_personne_responsable_rh(Responsable, Personne, DD, DF),
	DD =< To, 
	DF >= From, 
	!.

	









/*******************************************************************************
*
*
*                          GESTION DES FARRAY
*
*                      Bufferisation des données
*
*
% personne(+Name, update_array(+Array, +Event, +Obj))
*      Mise à jour des farrays sur une personne
*      Event = [add, remove]
*
*
% personne(+Name, set_array(+Array, +L))
*      Remplace les farrays par une nouvelle liste
*
*
% personne(+Name, get_array_no_sort(+Array, -L))
*      Renvoie les farrays tels quels (sans filtre ni tri)
*
*
% personne(+Name, get_array(+Array, -L)):-
*      Récupere les contrats/aptitudes/planning de la personne
*
*
% personne(+Name, get_array(+Array, +From, +To, -L))
*      Récupere les contrats/aptitudes/planning de la personne sur une période
* 
*
% personne(+Name, destroy_array(?Array))
*      Détruit les farrays attachés à une personne
*
*
% personne(+Name, init_array(+Array))
*      Initialise les farrays attachés à une personne
*
*******************************************************************************/
/*******************************************************************************
* Mise à jour des farrays sur une personne
* Event = [add, remove]
*******************************************************************************/
% Personne non instanciée
personne(Name, update_array(_, _, _)):-
	not instance(Name),
	!.
% Ajout
personne(Name, update_array(Array, add, Obj)):-
	not not $member(Array, [contrat, aptitude, planning, appart_equipe]),
	personne(Name, get_array_no_sort(Array, Contents)),

	% Repositionne le farray
	personne(Name, set_array(Array, [Obj|Contents])).


% Suppression
personne(Name, update_array(Array, remove, Obj)):-
	not not $member(Array, [contrat, aptitude, planning, appart_equipe]),
	personne(Name, get_array_no_sort(Array, Contents)),
	
	% Supprime l'objet de la liste
	delete(Obj, Contents, L),

	% Repositionne le farray
	personne(Name, set_array(Array, L)).



/*******************************************************************************
* Remplace les farrays par une nouvelle liste
*******************************************************************************/
% Personne non instanciée
personne(Name, set_array(_, _)):-
	not instance(Name),
	!.

personne(Name, set_array(Array, L)):-
	not not $member(Array, [planning, contrat, aptitude, appart_equipe]),
	instance(Name),
	sprintf(FArray, "%s_%s", [Name, Array]),
	!,
	farray(FArray, replace(L)).
personne(Name, set_array(Array, L)):-
	!,
	not not $member(Array, [planning, contrat, aptitude, appart_equipe]).




/*******************************************************************************
* Renvoie les farrays tels quels (sans filtre ni tri)
*******************************************************************************/
personne(Name, get_array_no_sort(Array, All)):-
	not not $member(Array, [planning, contrat, aptitude, appart_equipe]),
	sprintf(FArray, "%s_%s", [Name, Array]),
        farray(FArray, exists),
	!,
	farray(FArray, contents(All)).
personne(Name, get_array_no_sort(Array, [])):-
	!,
	not not $member(Array, [planning, contrat, aptitude, appart_equipe]).
	




/*******************************************************************************
* Récupere les contrats/aptitudes/planning/appart_equipe de la personne
*******************************************************************************/
% Appart Equipe
personne(Name, get_array(Array, All_Sorted)):-
	not not $member(Array, [appart_equipe]),
	personne(Name, get_array_no_sort(Array, All)),
	!,
	% Sécurité : ne conserve que les objets
 	util_get_attr_values(All, name, All_Filtred),

	% Trie les objets
	$list_attr_sort(All_Filtred, All_Sorted, debut, fin).
% Contrats
personne(Name, get_array(Array, All_Sorted)):-
	not not $member(Array, [contrat]),
	personne(Name, get_array_no_sort(Array, All)),
	!,
	% Sécurité : ne conserve que les objets
 	util_get_attr_values(All, name, All_Filtred),

	% Trie les objets
	$list_attr_sort(All_Filtred, All_Sorted, debut, fin).
% Aptitudes
personne(Name, get_array(Array, All_Sorted)):-
	not not $member(Array, [aptitude]),
	personne(Name, get_array_no_sort(Array, All)),
	!,
	% Sécurité : ne conserve que les objets
 	util_get_attr_values(All, name, All_Filtred),

	% Trie les objets
	$list_attr_sort(All_Filtred, All_Sorted, date_debut, date_fin).
% Planning
personne(Name, get_array(Array, All_Sorted)):-
	not not $member(Array, [planning]),
	personne(Name, get_array_no_sort(Array, All)),
	!,
	% Sécurité : ne conserve que les objets
 	util_get_attr_values(All, name, All_Filtred),
	
	% Trie les objets

 	$$list_sort_attr2(All_Filtred, All_Sorted, X, generic_get_dates(X@class, X, Start, End)-Start, generic_get_dates(X@class, X, Start, End)-End).
personne(Name, get_array(Array, [])):-
	!,
	not not $member(Array, [planning, contrat, aptitude, appart_equipe]).



/*******************************************************************************
* Récupere les contrats/aptitudes/planning/appart_equipe de la personne sur une période
*******************************************************************************/
% Appart_equipe
personne(Name, get_array(Array, From, To, All)):-
	not not $member(Array, [appart_equipe]),
	personne(Name, get_array(Array, All_Sorted)),
	!,
	util_filtre(All_Sorted, X, (X@date_debut =< To, X@date_fin >= From), All).
% Contrats
personne(Name, get_array(Array, From, To, All)):-
	not not $member(Array, [contrat]),
	personne(Name, get_array(Array, All_Sorted)),
	!,
	util_filtre(All_Sorted, X, (X@debut =< To, X@fin >= From), All).
% Aptitudes
personne(Name, get_array(Array, From, To, All)):-
	not not $member(Array, [aptitude]),
	personne(Name, get_array(Array, All_Sorted)),
	!,
	util_filtre(All_Sorted, X, (X@date_debut =< To, X@date_fin >= From), All).
% Planning
personne(Name, get_array(Array, From, To, All)):-
	not not $member(Array, [planning]),
	personne(Name, get_array(Array, All_Sorted)),
	!,
	util_filtre(All_Sorted, X, generic_is_in_period(X, From, To), All).
personne(Name, get_array(Array, From, T, [])):-
	!,
	not not $member(Array, [planning, contrat, aptitude, appart_equipe]).



/*******************************************************************************
* get array paramétrable :
*
* Attr = attribut avec déréférencement ex : personne-label
*
* Filtres = filtre(X, Goal)
*           no
*
* Sort = sort(X, Goal1-Sort1, Goal2-Sort2)
*        sort(Attr1, Attr2),
*        no
*
* Unique = unique(Unique_Attr, Unique_Sort_Attr)
*          unique
*******************************************************************************/
personne(Name, get_array(Array, Attr, Filtres, Sort, Unique, Values)):-
	personne(Name, get_array_no_sort(Array, All)),

	% 1- Filtre
	(Filtres = filtre(XF, Goal_Filtre) ->
	    util_filtre(All, XF, Goal_Filtre, All_Filtred)
	;
	    All_Filtred = All
	),

	% 2- Unique 
	(Unique = unique(Unique_Attr, Unique_Sort_Attr) ->
	    util_keep_one_instance(All_Filtred, Unique_Attr, Unique_Sort_Attr, All_Uniques)
	;
	    (Unique = unique ->
		util_distinct(All_Filtred, All_Uniques)
	    ;
		All_Uniques = All_Filtred
	    )
	),
		
	% 3- Trie
	(Sort = sort(XS, Goal1-Attr_Sort1, Goal2-Attr_Sort2) ->
	    $$list_sort_attr2(All_Uniques, All_Sorted, XS, Goal1-Attr_Sort1, Goal2-Attr_Sort2)
	;
	    (Sort = sort(Attr_Sort1, Attr_Sort2) ->
		$list_attr_sort(All_Uniques, All_Sorted, Attr_Sort1, Attr_Sort2)
	    ;
		All_Sorted = All_Uniques
	    )
	),
	(Attr \= name ->
	    util_get_ref_attr_values2(All_Sorted, Attr, Values)
	;
	    Values = All_Sorted
	).



/*******************************************************************************
* Détruit les farrays attachés à une personne
*******************************************************************************/
personne(Name, destroy_array(Array)):-
	$member(Array, [planning, contrat, aptitude, appart_equipe]),
	sprintf(FArray, "%s_%s", [Name, Array]),
	farray(FArray, destroy),
	fail.
personne(Name, destroy_array(Array)).




/*******************************************************************************
* Initialise les farrays attachés à une personne
*******************************************************************************/
% Initialise tous les tableaux
personne(Name, init_array):-
	not specific_parameter(personne_log_farray, off),
	personne(Name, init_array(appart_equipe)), 
	personne(Name, init_array(contrat)), 
	personne(Name, init_array(aptitude)), 
	personne(Name, init_array(planning)), 
	fail.
personne(Name, init_array).


% Appart Equipe
personne(Name, init_array(Array)):-
	not not $member(Array, [appart_equipe]),
	!,
	appart_equipe(_, get_appart_equipes(name, [ressource = Name], L)),
	personne(Name, set_array(Array, L)).
% Contrats
personne(Name, init_array(Array)):-
	not not $member(Array, [contrat]),
	!,
	all(contrat, name, [personne = Name], [], L),
	personne(Name, set_array(Array, L)).
% Aptitudes
personne(Name, init_array(Array)):-
	not not $member(Array, [aptitude]),
	!,
	aptitude(_, get_aptitudes(name, [ressource = Name], L)),
	personne(Name, set_array(Array, L)).
% Planning Micro
personne(Name, init_array(Array)):-
	appl_mode_planif(jour),
	not down_role(administrateur),
	not not $member(Array, [planning]),
	!,
    	all(etiquette, name, [personne = Name], [], L1),
	all(doublure_etiquette, name, [personne = Name], L1, L2),
	all(indispo_planif, name, [ressource = Name], L2, L3),
	all(d_tache, name, [ressource = Name], L3, L4),
	all(d_tache_cyclique, name, [ressource = Name], L4, L5),
	all(d_doublure, name, [ressource = Name], L5, L6),

	personne(Name, set_array(Array, L6)).
% Planning Horaire
personne(Name, init_array(Array)):-
	appl_mode_planif(heure),
	not down_role(administrateur),
	not not $member(Array, [planning]),
	!,
    	all(tache, name, [besoin-ressource = Name], [], L1),
	all(doublure, name, [ressource = Name], L1, L2),
    	all(tache_cyclique, name, [ressource = Name], L2, L3),
	all(vacation_t, name, [ressource = Name], L3, L4),
	all(indispo_planif, name, [ressource = Name], L4, L5),
	all(d_etiquette, name, [personne = Name], L5, L6),
	all(d_doublure_etiquette, name, [personne = Name], L6, L7),

	personne(Name, set_array(Array, L7)).
% Administrateur : Uniquement les indispos
personne(Name, init_array(Array)):-
	down_role(administrateur),
	not not $member(Array, [planning]),
	!,
	all(indispo_planif, name, [ressource = Name], [], L6),
	personne(Name, set_array(Array, L6)).
% Autres cas...
personne(Name, init_array(Array)).






/*******************************************************************************
* Renvoie les appart_equipes d''une personne selon les critères passés en paramètres
*******************************************************************************/
% Cas 1 : Filtre de type all
personne(Name, get_appart_equipes(Attr, Filtres_All, Result)):-
	% Récupère tous les appart_equipes de la personne
	personne(Name, get_array_no_sort(appart_equipe, All_Appart_equipes)),

	(not atom(Attr) ->
	    $list_obj_filter(All_Appart_equipes, name, Filtres_All, Appart_equipes_Filtred, _, _),
	    util_get_ref_attr_values2(Appart_equipes_Filtred, Attr, Result)
	;
	    $list_obj_filter(All_Appart_equipes, Attr, Filtres_All, Result, _, _)
	).


% Cas 2 : Filtre prolog
personne(Name, get_appart_equipes(Attr, X, Filtres, Result)):-
	% Récupère tous les appart_equipes de la personne
	personne(Name, get_array_no_sort(appart_equipe, All_Appart_equipes)),
	
	% Les filtre
	(Filtres \= true ->
	    util_filtre(All_Appart_equipes, X, Filtres, Appart_equipes_Filtred)
	;
	    Appart_equipes_Filtred = All_Appart_equipes
	),
	
	% Récupère le bon attribut
	(Attr \= name ->
	    (atom(Attr) ->
		% Attribut simple
		util_get_attr_values_full(Appart_equipes_Filtred, Attr, Result)
	    ;
		% Attribut avec déréférencement
		util_get_ref_attr_values2(Appart_equipes_Filtred, Attr, Result)
	    )
	;
	    Result = Appart_equipes_Filtred
	).




/*******************************************************************************
* Renvoie les appart_equipes d''une personne selon les critères passés en paramètres
* une par une avec backtrack
*******************************************************************************/
% Cas 1 : Filtre de type all
personne(Name, get_appart_equipe(Attr, Filtres_All, Appart_equipe)):-
	personne(Name, get_appart_equipes(Attr, Filtres_All, Appart_equipes)),
	!,
	$member(Appart_equipe, Appart_equipes).
	
% Cas 2 : Filtre prolog
personne(Name, get_appart_equipe(Attr, X, Filtres, Appart_equipe)):-
	personne(Name, get_appart_equipes(Attr, X, Filtres, Appart_equipes)),
	!,
	$member(Appart_equipe, Appart_equipes).



/*******************************************************************************
* Renvoie les contrats d''une personne selon les critères passés en paramètres
*******************************************************************************/
% Cas 1 : Filtre de type all
personne(Name, get_contrats(Attr, Filtres_All, Result)):-
	% Récupère tous les contrats de la personne
	personne(Name, get_array_no_sort(contrat, All_Contrats)),

	(not atom(Attr) ->
	    $list_obj_filter(All_Contrats, name, Filtres_All, Contrats_Filtred, _, _),
	    util_get_ref_attr_values2(Contrats_Filtred, Attr, Result)
	;
	    $list_obj_filter(All_Contrats, Attr, Filtres_All, Result, _, _)
	).

% Cas 2 : Filtre prolog
personne(Name, get_contrats(Attr, X, Filtres, Result)):-
	% Récupère tous les contrats de la personne
	personne(Name, get_array_no_sort(contrat, All_Contrats)),
	
	% Les filtre
	(Filtres \= true ->
	    util_filtre(All_Contrats, X, Filtres, Contrats_Filtred)
	;
	    Contrats_Filtred = All_Contrats
	),
	
	% Récupère le bon attribut
	(Attr \= name ->
	    (atom(Attr) ->
		% Attribut simple
		util_get_attr_values_full(Contrats_Filtred, Attr, Result)
	    ;
		% Attribut avec déréférencement
		util_get_ref_attr_values2(Contrats_Filtred, Attr, Result)
	    )
	;
	    Result = Contrats_Filtred
	).



/*******************************************************************************
* Renvoie les contrats d''une personne selon les critères passés en paramètres
* une par une avec backtrack
*******************************************************************************/
% Cas 1 : Filtre de type all
personne(Name, get_contrat(Attr, Filtres_All, Contrat)):-
	personne(Name, get_contrats(Attr, Filtres_All, Contrats)),
	!,
	$member(Contrat, Contrats).
	
% Cas 2 : Filtre prolog
personne(Name, get_contrat(Attr, X, Filtres, Contrat)):-
	personne(Name, get_contrats(Attr, X, Filtres, Contrats)),
	!,
	$member(Contrat, Contrats).






/*******************************************************************************
* Renvoie les aptitudes d''une personne selon les critères passés en paramètres
*******************************************************************************/
% Cas 1 : Filtre de type all
personne(Name, get_aptitudes(Attr, Filtres_All, Result)):-
	% Récupère tous les aptitudes de la personne
	personne(Name, get_array_no_sort(aptitude, All_Aptitudes)),

	(not atom(Attr) ->
	    $list_obj_filter(All_Aptitudes, name, Filtres_All, Aptitudes_Filtred, _, _),
	    util_get_ref_attr_values2(Aptitudes_Filtred, Attr, Result)
	;
	    $list_obj_filter(All_Aptitudes, Attr, Filtres_All, Result, _, _)
	).


% Cas 2 : Filtre prolog
personne(Name, get_aptitudes(Attr, X, Filtres, Result)):-
	% Récupère tous les aptitudes de la personne
	personne(Name, get_array_no_sort(aptitude, All_Aptitudes)),
	
	% Les filtre
	(Filtres \= true ->
	    util_filtre(All_Aptitudes, X, Filtres, Aptitudes_Filtred)
	;
	    Aptitudes_Filtred = All_Aptitudes
	),
	
	% Récupère le bon attribut
	(Attr \= name ->
	    (atom(Attr) ->
		% Attribut simple
		util_get_attr_values_full(Aptitudes_Filtred, Attr, Result)
	    ;
		% Attribut avec déréférencement
		util_get_ref_attr_values2(Aptitudes_Filtred, Attr, Result)
	    )
	;
	    Result = Aptitudes_Filtred
	).
	




/*******************************************************************************
* Renvoie les aptitudes d''une personne selon les critères passés en paramètres
* une par une avec backtrack
*******************************************************************************/
% Cas 1 : Filtre de type all
personne(Name, get_aptitude(Attr, Filtres_All, Aptitude)):-
	personne(Name, get_aptitudes(Attr, Filtres_All, Aptitudes)),
	!,
	$member(Aptitude, Aptitudes).
	
% Cas 2 : Filtre prolog
personne(Name, get_aptitude(Attr, X, Filtres, Aptitude)):-
	personne(Name, get_aptitudes(Attr, X, Filtres, Aptitudes)),
	!,
	$member(Aptitude, Aptitudes).





/*******************************************************************************
* Renvoie le planning d''une personne selon les critères passés en paramètres
*******************************************************************************/
% Cas 1a : Filtre de type all, module jour
personne(Name, get_planning(From, To, Filtres, Result)):-
	appl_mode_planif(jour),
	not down_role(administrateur),
	!,
	% Récupère tous le planning de la personne
	personne(Name, get_array_no_sort(planning, All_Planning)),

	% 1- Filtre sur la période
	To_Indispo is To + 1440,
	
	$list_obj_filter(All_Planning, name, (((class=etiquette) and (jour_planif =< To) and (jour_planif >= From)) or
	                                      ((class=doublure_etiquette) and (jour_planif =< To) and (jour_planif >= From)) or
	                                      ((class=indispo_planif) and (date_debut < To_Indispo) and (date_debut >= From)) or
	                                      ((class=d_tache) and (jour_planifie =< To) and (jour_planifie >= From)) or
	                                      ((class=d_tache_cyclique) and (jour_planifie =< To) and (jour_planifie >= From)) or
	                                      ((class=d_doublure) and (jour_planifie =< To) and (jour_planifie >= From))), Planning_Periode, _, _),
	% 2- Filtre perso
	$list_obj_filter(Planning_Periode, name, Filtres, Result, _, _).

% Cas 1b : Filtre de type all, module horaire
personne(Name, get_planning(From, To, Filtres, Result)):-
	not appl_mode_planif(jour),
	not down_role(administrateur),
	!,
	% Récupère tous le planning de la personne
	personne(Name, get_array_no_sort(planning, All_Planning)),

	% 1- Filtre sur la période
	To_Indispo is To + 1440,
	
	$list_obj_filter(All_Planning, name, (((class=tache) and (besoin-module-jour_planifie =< To) and (besoin-module-jour_planifie >= From)) or
	                                      ((class=doublure) and (tache-besoin-module-jour_planifie =< To) and (tache-besoin-module-jour_planifie >= From)) or
	                                      ((class=tache_cyclique) and (jour_planifie =< To) and (jour_planifie >= From)) or
	                                      ((class=vacation_t) and (jour_planifie =< To) and (jour_planifie >= From)) or
	                                      ((class=indispo_planif) and (date_debut < To_Indispo) and (date_debut >= From)) or
					      ((class=d_etiquette) and (jour_planif =< To) and (jour_planif >= From)) or
					      ((class=d_doublure_etiquette) and (jour_planif =< To) and (jour_planif >= From))), Planning_Periode, _, _),
	% 2- Filtre perso
	$list_obj_filter(Planning_Periode, name, Filtres, Result, _, _).

% Cas 1c : Filtre de type all, module admin
personne(Name, get_planning(From, To, Filtres, Result)):-
	down_role(administrateur),
	!,
	% Récupère tous le planning de la personne
	personne(Name, get_array_no_sort(planning, All_Planning)),

	% 1- Filtre sur la période
	To_Indispo is To + 1440,
	
	$list_obj_filter(All_Planning, name, (((class=indispo_planif) and (date_debut < To_Indispo) and (date_debut >= From))), Planning_Periode, _, _),
	% 2- Filtre perso
	$list_obj_filter(Planning_Periode, name, Filtres, Result, _, _).
personne(Name, get_planning(From, To, Filtres, [])).


% Cas 2 : Filtre prolog
personne(Name, get_planning(From, To, X, Filtres, Result)):-
	personne(Name, get_array_no_sort(planning, All_Planning)),
	
	% Le filtre
	util_filtre(All_Planning, X, (generic_is_in_period(X, From, To), Filtres), Result).

	

/*******************************************************************************
* Renvoie le planning d''une personne (Trié) selon les critères passés en paramètres
*******************************************************************************/
personne(Name, get_planning_sorted(From, To, Filtres, Result_Sorted)):-
	personne(Name, get_planning(From, To, Filtres, Result)),	
	$$list_sort_attr2(Result, Result_Sorted, Obj, generic_get_dates(Obj@class, Obj, Start, End)-Start, generic_get_dates(Obj@class, Obj, Start, End)-End).


personne(Name, get_planning_sorted(From, To, X, Filtres, Result_Sorted)):-
	personne(Name, get_planning(From, To, X, Filtres, Result)),	
	$$list_sort_attr2(Result, Result_Sorted, Obj, generic_get_dates(Obj@class, Obj, Start, End)-Start, generic_get_dates(Obj@class, Obj, Start, End)-End).





	

/*******************************************************************************
% PART
*
*
%
*
*
*
*******************************************************************************/
% /*******************************************************************************
% * Calcul des compteurs
% *******************************************************************************/
% personne(Name, calcule_compteur(Type, Unit, Date, Total)):-
% 	compteur_get_duree(Name, Type, Unit, Date, Total).



% /*******************************************************************************
% * Positionne le compteur de la personne à la bonne valeur
% *******************************************************************************/
% personne(Name, calcule_and_set_compteur(Type, Unit, Attr, Date)):-
% 	compteur_get_duree(Name, Type, Unit, Date, Total),
% 	Name@Attr <- Total.



% /*******************************************************************************
% * Calcule la durée totale travaillée sur une période
% *******************************************************************************/
% personne(Name, calcule_compteur_periode(Unit, From, To, Total)):-
% 	compteur_get_duree_periode(Name, Unit, From, To, Total).



% /*******************************************************************************
% * Renvoie la durée totale d''un planning donné
% *******************************************************************************/
% personne(Name, calcule_compteur_planning(Unit, From, To, Planning, Total)):-
% 	compteur_get_duree_planning(Name, Unit, From, To, Planning, Total).








/*******************************************************************************
% PART
*
*
%       TESTS 
*
*
*
*******************************************************************************/
/*******************************************************************************
* Sauvegarde dans un fichier de log s''il y a des différences entre les
* farray et les données
*******************************************************************************/
% Ouvre un flux
personne_log_farray:-
	appl_getenv('OPTIDIR', Dir),
	sprintf(File, "%s\\DATA\\farray.log", [Dir]),
	util_writeable(File),
	!,
	open(File, Stream, a),
	personne_log_farray(Stream).
personne_log_farray.


personne_log_farray(Stream):-
	setval($log_nb_appart_equipe, 0),
	setval($log_nb_contrat, 0),
	setval($log_nb_aptitude, 0),
	setval($log_nb_planning, 0),
	fail.
personne_log_farray(Stream):-
	get_prolog_flag(date, date(YYYY, MM, DD, HH, Mi, SS)),
	nl(Stream),
	writeln(Stream, '---------------------------------------------'),
	fprintf(Stream, "Date : %02d/%02d/%04d %02d:%02d:%02d\n", [DD, MM, YYYY, HH, Mi, SS]),
        down_role(Role_Type, Role),
	fprintf(Stream, "Role : %s - %s\n", [Role_Type, Role]),
        fail.
personne_log_farray(Stream):-
	iss_a(Name, personne),
	
	% Vérification des appart_equipes
	all(appart_equipe, name, [ressource = Name], [], Appart_equipes0),
	$list_attr_sort(Appart_equipes0, Appart_equipes, db_key, db_key),
	personne(Name, get_array_no_sort(appart_equipe, Appart_equipes_Array0)),
	$list_attr_sort(Appart_equipes_Array0, Appart_equipes_Array, db_key, db_key),
	
	anyway((Appart_equipes \= Appart_equipes_Array,
		incval($log_nb_appart_equipe, Nb_Appart_equipe),
		true
	)),


	% Vérification des contrats
	all(contrat, name, [personne = Name], [], Contrats0),
	$list_attr_sort(Contrats0, Contrats, db_key, db_key),
	personne(Name, get_array_no_sort(contrat, Contrats_Array0)),
	$list_attr_sort(Contrats_Array0, Contrats_Array, db_key, db_key),
	
	anyway((Contrats \= Contrats_Array,
		incval($log_nb_contrat, Nb_Contrat),
		true
	)),
	
	% Vérification des aptitudes
	all(aptitude, name, [ressource = Name], [], Aptitudes0),
	$list_attr_sort(Aptitudes0, Aptitudes, db_key, db_key),
	personne(Name, get_array_no_sort(aptitude, Aptitudes_Array0)),
	$list_attr_sort(Aptitudes_Array0, Aptitudes_Array, db_key, db_key),
	
	anyway((Aptitudes \= Aptitudes_Array,
		incval($log_nb_aptitude, Nb_Aptitude),
		true
	)),

	% Vérification des activites
	(appl_mode_planif(jour), not down_role(administrateur) ->
	
	    all(etiquette, name, [personne = Name], [], L1),
	    all(doublure_etiquette, name, [personne = Name], L1, L2),
	    all(indispo_planif, name, [ressource = Name], L2, L3),
	    all(d_tache, name, [ressource = Name], L3, L4),
	    all(d_tache_cyclique, name, [ressource = Name], L4, L5),
	    all(d_doublure, name, [ressource = Name], L5, Planning0),
	    $list_attr_sort(Planning0, Planning, name, name)
	;
	    (appl_mode_planif(heure), not down_role(administrateur) ->
	    
		all(tache, name, [besoin-ressource = Name], [], P1),
		all(doublure, name, [ressource = Name], P1, P2),
		all(indispo_planif, name, [ressource = Name], P2, P3),
		all(tache_cyclique, name, [ressource = Name], P3, P4),
		all(vacation_t, name, [ressource = Name], P4, P5),
		all(d_etiquette, name, [personne = Name], P5, P6),
		all(d_doublure_etiquette, name, [personne = Name], P6, Planning0),
		$list_attr_sort(Planning0, Planning, name, name)
	    ;
		fail
	    )
	),
	    
	personne(Name, get_array_no_sort(planning, Planning_Array0)),
	$list_attr_sort(Planning_Array0, Planning_Array, name, name),
	
	anyway((Planning \= Planning_Array,
	        incval($log_nb_planning, Nb_Planning)
	    )),

	fail.
personne_log_farray(Stream):-
	all(personne, name, [], [], Personnes),
	length(Personnes, Nb_Personnes),
	fprintf(Stream, "Différences sur %s personnes :\n", [Nb_Personnes]),

	getval($log_nb_appart_equipe, Nb_Appart_equipe),
	fprintf(Stream, "Appart_equipes : %s\n", [Nb_Appart_equipe]),


	getval($log_nb_contrat, Nb_Contrat),
	fprintf(Stream, "Contrats : %s\n", [Nb_Contrat]),

	getval($log_nb_aptitude, Nb_Aptitude),
	fprintf(Stream, "Aptitudes : %s\n", [Nb_Aptitude]),

	down_role_in_list(planificateur, [micro_planificateur, gestionnaire_micro, type_ressource, gestionnaire, absence, emission]),
	getval($log_nb_planning, Nb_Planning),
	fprintf(Stream, "Planning : %s\n", [Nb_Planning]),

	fail.
personne_log_farray(Stream):-
	close(Stream).


/*******************************************************************************
* Renvoie un CN sur lequel les espaces de droites et de gauches ont été 
* supprimés et le tout mis en minuscules
*******************************************************************************/
personne_cn_normalize(CN, New_CN):-
	util_upper_case(CN, CN1),
	util_ltrim(CN1, ' ', CN2),
	util_rtrim(CN2, New_CN).   % Arithé 2 n'existe pas....



/*******************************************************************************
% personne(+Personne, get_derniere_equipe_principale(-Equipe)
* Donne la dernière équipe principale à laquelle la Personne 'a' appartenu. 
*******************************************************************************/
% get_derniere_equipe_principale/1
personne(Personne, get_derniere_equipe_principale(Equipe)):-
	Aujourdhui is (mode@now/1440) * 1440,
	personne(Personne, get_derniere_equipe_principale(Aujourdhui, Equipe)),
	!.


/*******************************************************************************
% personne(+Personne, get_derniere_equipe_principale(+Date, -Equipe)
* Donne la dernière équipe principale à laquelle la personne 'a' appartenu avant la date Date.
*******************************************************************************/
% get_derniere_equipe_principale/2
% Regarde d'abord en mémoire
personne(Personne, get_derniere_equipe_principale(Date, Equipe)):-
	personne(Personne, get_equipes_principales_sorted(0, Date, EQPs)),
	EQPs \= [],
	util_reverse(EQPs, [Derniere_Appart_Equipe|_]),
	Equipe = Derniere_Appart_Equipe@equipe_redactionnelle,
	!.
% Regarde ensuite en base
personne(Personne, get_derniere_equipe_principale(Date, Equipe)):-
	Db_key = Personne@db_key,
	mu_db_tuple("SELECT 'equipe_redactionnelle_'||EQUIPE_REDACTIONNELLE FROM OPTI_APPART_EQUIPE E1
	  	     WHERE E1.RESSOURCE = %s AND E1.PRINCIPAL = '1' AND E1.DATE_DEBUT <= TRUNC(SYSDATE, 'J')
	  	     AND NOT EXISTS (SELECT DB_KEY FROM OPTI_APPART_EQUIPE E2 WHERE E2.RESSOURCE = %s 
		                     AND E2.PRINCIPAL = '1' AND E2.DATE_DEBUT <= TRUNC(SYSDATE, 'J')
				     AND E2.DATE_DEBUT > E1.DATE_DEBUT)", [Db_key, Db_key], Tuple),
	Tuple = tuple(Equipe),
	!.

/*******************************************************************************
% personne(+Personne, getsion_appart_equipe_impossible(-Msg))
* Méthode mise en place pour la gestion de la délégation (notion de prêt de collaborateurs entre équipes du même site/ de sites différents) 
* Demande de Gestion de la délégation issue de FMM (initialement)
* Réussit si les appartenances aux équipes de la personne ne peuvent pas être modifiées et retourne un Message à afficher
*******************************************************************************/
personne(Personne, getsion_appart_equipe_impossible(Msg)):-   
	not down_role(administrateur), % Pas de contrôle en administrateur
	personne(Personne, get_derniere_equipe_principale(Equipe_collaborateur)),
	Equipe_red = jour_parameter@equipe_redactionnelle,
	Site_red = (Equipe_red@direction)@site,
	(instance(Equipe_collaborateur) ->
	    % Si Equipe_collaborateur existe en mémoire	    
	    Regle = Equipe_collaborateur@regle_delegation,
	    Nom_Equipe_collaborateur = Equipe_collaborateur@nom,
	    (instance(Equipe_collaborateur@direction) ->
		Site_collaborateur = (Equipe_collaborateur@direction)@site,
		Nom_Site_collaborateur = Site_collaborateur@nom
	    ;
		mu_db_tuple("SELECT 'site_'||OPTI_SITE.DB_KEY, OPTI_SITE.NOM FROM OPTI_DIRECTION, OPTI_SITE 
	                             WHERE OPTI_DIRECTION.SITE = OPTI_SITE.DB_KEY
	                             AND OPTI_DIRECTION.DB_KEY = SUBSTR('%s', 11)", [Equipe_collaborateur@direction], Tuple1),
		Tuple1 = tuple(Site_collaborateur, Nom_Site_collaborateur)
	    )
	;
	    % Sinon, on cherche les infos dont on a besoin en base  
	    mu_db_tuple("SELECT OPTI_EQUIPE_REDACTIONNEL.REGLE_DELEGATION, OPTI_EQUIPE_REDACTIONNEL.NOM, 'site_'||OPTI_SITE.DB_KEY, OPTI_SITE.NOM 
	                 	                       FROM OPTI_EQUIPE_REDACTIONNEL, OPTI_DIRECTION, OPTI_SITE
	                 	                       WHERE OPTI_EQUIPE_REDACTIONNEL.DB_KEY = SUBSTR('%s', 23) AND OPTI_EQUIPE_REDACTIONNEL.DIRECTION = OPTI_DIRECTION.DB_KEY 
						       AND OPTI_DIRECTION.SITE = OPTI_SITE.DB_KEY", [Equipe_collaborateur], Tuple2),
	    Tuple2 = tuple(Regle, Nom_Equipe_collaborateur, Site_collaborateur, Nom_Site_collaborateur)
	),
	(Regle = '2' ->
	    % On ne peut pas modifier les appartenances d'une personne si sa dernière équipe principale n'est pas celle chargée
	    Equipe_red \= Equipe_collaborateur,
	    sprintf(Msg, text@echec_controle_delegation_intra_site, [Nom_Equipe_collaborateur])
	;
	    Regle = '1',
	    % On ne peut pas modifier les appartenances d'une personne si sa dernière équipe principale n'appartient pas au site de l'équipe chargée
	    Site_red \= Site_collaborateur,
	    sprintf(Msg, text@echec_controle_delegation_inter_site, [Site_collaborateur@nom])	
	),
	!. 



/*******************************************************************************
* Réussi l''objet de controle est au niveau du site ou de l''équipe
*******************************************************************************/
personne(Personne, get_control_level(Objet)):-   
	not down_role(administrateur), % Pas de contrôle en administrateur
	personne(Personne, get_derniere_equipe_principale(Equipe_collaborateur)),
	Equipe_red = jour_parameter@equipe_redactionnelle,
	Site_red = (Equipe_red@direction)@site,
	(instance(Equipe_collaborateur) ->
	    % Si Equipe_collaborateur existe en mémoire	    
	    Regle = Equipe_collaborateur@regle_delegation,
	    Nom_Equipe_collaborateur = Equipe_collaborateur@nom,
	    (instance(Equipe_collaborateur@direction) ->
		Site_collaborateur = (Equipe_collaborateur@direction)@site,
		Nom_Site_collaborateur = Site_collaborateur@nom
	    ;
		mu_db_tuple("SELECT 'site_'||OPTI_SITE.DB_KEY, OPTI_SITE.NOM FROM OPTI_DIRECTION, OPTI_SITE 
	                             WHERE OPTI_DIRECTION.SITE = OPTI_SITE.DB_KEY
	                             AND OPTI_DIRECTION.DB_KEY = SUBSTR('%s', 11)", [Equipe_collaborateur@direction], Tuple1),
		Tuple1 = tuple(Site_collaborateur, Nom_Site_collaborateur)
	    )
	;
	    % Sinon, on cherche les infos dont on a besoin en base  
	    mu_db_tuple("SELECT OPTI_EQUIPE_REDACTIONNEL.REGLE_DELEGATION, OPTI_EQUIPE_REDACTIONNEL.NOM, 'site_'||OPTI_SITE.DB_KEY, OPTI_SITE.NOM 
	                 	                       FROM OPTI_EQUIPE_REDACTIONNEL, OPTI_DIRECTION, OPTI_SITE
	                 	                       WHERE OPTI_EQUIPE_REDACTIONNEL.DB_KEY = SUBSTR('%s', 23) AND OPTI_EQUIPE_REDACTIONNEL.DIRECTION = OPTI_DIRECTION.DB_KEY 
						       AND OPTI_DIRECTION.SITE = OPTI_SITE.DB_KEY", [Equipe_collaborateur], Tuple2),
	    Tuple2 = tuple(Regle, Nom_Equipe_collaborateur, Site_collaborateur, Nom_Site_collaborateur)
	),
	(Regle = '2' ->
	    % On ne peut pas modifier les appartenances d'une personne si sa dernière équipe principale n'est pas celle chargée
	    % Renvoie l''équipe du collaborateur
	    Objet = Equipe_collaborateur
	    
	;
	    Regle = '1',
	    % On ne peut pas modifier les appartenances d'une personne si sa dernière équipe principale n'appartient pas au site de l'équipe chargée
	    % Renvoie le site
	    Objet = Site_collaborateur
	),
	!. 


/*******************************************************************************
% personne(+Personne, is_salarie_etranger)
*       réussit si la personne est un salarié étranger
*
*******************************************************************************/
personne(Personne, is_salarie_etranger):-
	Personne@class = personne,
	Personne@type = '1',
	t(Personne@rens_num_carte_sejour, Personne@rens_num_carte_travail) \= t('', ''),
	!.


/*******************************************************************************
% personne(+Personne, autorisation_de_travail(-From, -To))
* retourne la période de validité de l''autorisation de travail pour un salarié étranger
*
*******************************************************************************/
personne(Personne, autorisation_de_travail(From, To)):-
	Personne@class = personne,
	Personne@rens_num_carte_sejour \= '',
	From = Personne@rens_date_carte_sejour,
	util_scan(Personne@rens_duree_carte_sejour, "%d/%d/%d", [Day, Month, Year]),
        date_convert(date(Year, Month, Day, 0, 0, 0), To),
	!.

personne(Personne, autorisation_de_travail(From, To)):-
	Personne@class = personne,
	Personne@rens_num_carte_travail \= '',
	From = Personne@rens_num_carte_travail,
	util_scan(Personne@rens_duree_carte_travail, "%d/%d/%d", [Day, Month, Year]),
        date_convert(date(Year, Month, Day, 0, 0, 0), To),
	!.
        
        

/*******************************************************************************
% personnes_get_nom_prenom(Personnes, Nom_Prenoms)
* Retourne les 'Nom Prénom' d''une liste de personnes
*******************************************************************************/
personnes_get_nom_prenom(Personnes, Nom_Prenoms):-
	personnes_get_nom_prenom_lp(Personnes, Nom_Prenoms0),
	util_build_list2(Nom_Prenoms0, Nom_Prenoms).

personnes_get_nom_prenom_lp([], []).
personnes_get_nom_prenom_lp([Personne|Rest_Personnes], [Nom_Prenom|Rest_Nom_Prenoms]):-
	sprintf(Nom_Prenom, "%s %s", [Personne@nom, Personne@prenom]),
        personnes_get_nom_prenom_lp(Rest_Personnes, Rest_Nom_Prenoms),
	!.



/*******************************************************************************
* Réussi si la personne est anonyme
*******************************************************************************/
personne(Res, si_anonyme):-
	!,
	Res@cdd_anonyme = 1.



/*******************************************************************************
* Conditions Méthodes
*******************************************************************************/
personne_responsable_rh_cond(_, X):-
	is_a(X, responsable_rh),
	site(_, is_loaded(responsable_rh, X)).


/*******************************************************************************
*
*
*                METHODES POUR LA FERMETURE DE CONTRAT
*
*
*******************************************************************************/
/*******************************************************************************
* Fermeture de contrat
*******************************************************************************/
personne(Personne, run_sortie_societe(Date, Options, Flag)):-
	retractall(personne_buffer_suppression_desaffectation_db(_,_)),
	personne(Personne, check_sortie_societe(Date, Options, Flag)),
	personne(Personne, set_sortie_societe(Date, Options, Flag)),
	true.
	
personne(Personne, set_sortie_societe(Date, Options, Flag)):-
	$member(Option-Value, Options),
	Value=on,
	personne_fermeture_elements(Personne, Date, Option),
	fail.
personne(Personne, set_sortie_societe(Date, Options, Flag)).

/*******************************************************************************
* On demande confirmation pour chaque fermeture, selon le Flag
* flag = 1 -> affichage du message de confirmation, sinon on ne l'affiche pas
*******************************************************************************/
personne(Personne, check_sortie_societe(Date, Options, 1)):-
	personne_fermeture_elements_alert_lp(Personne, Date, Options, ToClose00, ToDel00, Actions00),
	util_list_delete([''], ToClose00, ToClose0),
	util_list_delete([''], ToDel00, ToDel0),
	util_list_delete([''], Actions00, Actions0),
	util_build_list2(ToClose0, ToClose),
	util_build_list2(ToDel0, ToDel),
	util_build_list2(Actions0, Actions),
	!,
	personne_fermeture_elements_make_msg(Msg, ToClose, ToDel, Actions),
	alert(Msg,[text@continuer, text@cancel], text@continuer),
	true.
personne(Personne, check_sortie_societe(Date, Options, 0)).

/*******************************************************************************
* Methode pour les alertes
*******************************************************************************/
personne_fermeture_elements_alert_lp(Personne, Date, [], [], [], []).
personne_fermeture_elements_alert_lp(Personne, Date, [Option|OtherOptions], [TC|OtherTC], [TD|OtherTD], [Action|OtherActions]):-
	personne_fermeture_elements_alert(Personne, Date, Option, TC, TD, Action),
	personne_fermeture_elements_alert_lp(Personne, Date, OtherOptions, OtherTC, OtherTD, OtherActions).	
personne_fermeture_elements_alert_lp(Personne, Date, Options, ToClose, ToDel, Actions).
	
personne_fermeture_elements_alert(Personne, Date, Element-off,'','',''):-
	!.
% Contrats, aptitudes, appartenances equipe, occupations fonction, occupations grade, appartenances population -> fermer
personne_fermeture_elements_alert(Personne, Date, Element-on, ToClose, ToDel,''):-
	$member(Element-Class-RessourceAttr, [si_fermer_contrat-contrat-personne, si_fermer_aptitude-aptitude-ressource, si_fermer_appart_equipe-appart_equipe-ressource, 
	                                      si_fermer_fonction-occupation_fonction-personne, si_fermer_qualification-occupation_grade-personne,
				              si_fermer_population-appart_population-ressource]),
	($member(Class, [aptitude, appart_equipe, occupation_grade, appart_population]) -> 
	    DateDebutAttr = date_debut,
	    DateFinAttr = date_fin
	;
	    ($member(Class, [contrat, occupation_fonction]) -> 
		DateDebutAttr = debut,
		DateFinAttr = fin
	    ;
		true
	    )
	),

	% Contrats commançant après la date de sortie -> supprimer
	all(contrat, name, [personne = Personne, debut > Date], [], Contrats),
	(Class == contrat, Contrats \= [] ->
	    ToDel = 'Contrat (et les contingents et quotas associés)'
	;
	    ToDel = ''
	),
	% Objets (dont les contrats) commencant avant la date de sortie et finissant strictement après celle ci
	all(Class, name, [RessourceAttr = Personne, DateFinAttr > Date], [], Objs),
	(Objs \= [] ->
	    ToClose = text@Class
	;
	    ToClose = ''
	),
	!.
% Contingents et quotas -> fermer
personne_fermeture_elements_alert(Personne, Date, Element-on, text@Class,'',''):-
	$member(Element-Class-DateDebutAttr-DateFinAttr, [si_fermer_contingent-contingent-debut-fin, si_fermer_quota-quota-date_debut-date_fin]),
	all(Class, name, [contrat-personne = Personne, DateDebutAttr =< Date, DateFinAttr > Date], [], Objs),
	Objs \= [],
	!.
% Rôle Web
personne_fermeture_elements_alert(Personne, Date, si_fermer_role_web-on, 'rôles WEB','',''):-
	all(web_role_personne, name, [personne = Personne, date_debut =< Date, date_fin > Date], [], Objs0),
	all(web_role_utilisateur, name, [utilisateur-numero_matricule = Personne@numero_matricule, date_debut =< Date, date_fin > Date], Objs0, Objs),
	writeln(obj-Objs),
	Objs \= [],
	!.
% Personne -> fermer
personne_fermeture_elements_alert(Personne, Date, si_fermer_personne-on,'','','mise à jour de la date de sortie de société'):-
	!.
% Planning -> A revoir: peut etre qu'une consultation en base pourrait suffire
personne_fermeture_elements_alert(Personne, Date, si_desaffecter_planning-on,'','','désaffectation et/ou suppression d''activités dans le planning'):-
	DateD is Date + 1440,
	%% Objets en memoire
	personne(Personne, get_planning(DateD, mode@end_date, [], Planning)),
	all(marqueur, name, [ressource = Personne, date >= DateD, date =< mode@end_date], Planning, Activites_List),
	writeln(activites-Activites_List),
	%% Objets en base
	personne_search_planning(Personne@db_key, Date, Planning_db),
	writeln(planning_db-Planning_db),
	(Planning_db \= [];
	Activites_List \= []),	
	!.
% Demande de congés
personne_fermeture_elements_alert(Personne, Date, si_annuler_demandes_conges-on,'','','annulation de demandes de congés'):-
	all(demande_conges, name, [personne = Personne, date_debut > Date], [], Objs),
	Objs \= [],
	!.
personne_fermeture_elements_alert(Personne, Date, Option,'','','').

/*******************************************************************************
* Methode de creation message
*******************************************************************************/
personne_fermeture_elements_make_msg(Msg, ToClose, ToDel, Actions):-
	personne_fermeture_elements_make_msg(close, ToClose, Msg1),
	personne_fermeture_elements_make_msg(delete, ToDel,  Msg2),
	personne_fermeture_elements_make_msg(action, Actions, Msg3),
	sprintf(Msg0,"%s%s%s",[Msg1,Msg2,Msg3]),
	Msg0\='',
	sprintf(Msg,"Les actions suivantes vont être effectuées :\n%s\n\nVoulez-vous continuer ?",[Msg0]).

personne_fermeture_elements_make_msg(_,'',''):-
	!.
personne_fermeture_elements_make_msg(close, ToClose, Msg):-
	sprintf(Msg, "\n- fermeture d'élément(s) de type : %s",[ToClose]).
personne_fermeture_elements_make_msg(delete, ToDel, Msg):-
	sprintf(Msg, "\n- suppression d'élément(s) de type : %s",[ToDel]).
personne_fermeture_elements_make_msg(action, Actions, Msg):-
	sprintf(Msg, "\n- %s",[Actions]).
	

/*******************************************************************************
* Methode de fermeture des elements
*******************************************************************************/
% Contrats, aptitudes, appartenances equipe, occupations fonction, occupations grade, appartenances population
personne_fermeture_elements(Personne, Date, Element):-
	$member(Element-Class-RessourceAttr, [si_fermer_contrat-contrat-personne, si_fermer_aptitude-aptitude-ressource, si_fermer_appart_equipe-appart_equipe-ressource, 
	                                      si_fermer_fonction-occupation_fonction-personne, si_fermer_qualification-occupation_grade-personne,
				              si_fermer_population-appart_population-ressource]),
	writeln(fermeture1-Class),
	($member(Class, [aptitude, appart_equipe, occupation_grade, appart_population]) -> 
	    DateDebutAttr = date_debut,
	    DateFinAttr = date_fin
	;
	    ($member(Class, [contrat, occupation_fonction]) -> 
		DateDebutAttr = debut,
		DateFinAttr = fin
	    ;
		true
	    )
	),
	all(Class, name, [RessourceAttr = Personne, DateFinAttr > Date], [], Objs),
	$member(Obj, Objs),
	(Obj@DateDebutAttr =< Date ->
	    Goal=..[Class, Obj, set_atts([DateFinAttr <- Date])]
	;
	    (Class == contrat ->
		Goal=..[Class, Obj, destroy_cascade]
	    ;
		Goal=..[Class, Obj, destroy]
	    )
	),
	call(Goal),
	fail.
% Contingents et quotas
personne_fermeture_elements(Personne, Date, Element):-
	$member(Element-Class-DateDebutAttr-DateFinAttr, [si_fermer_contingent-contingent-debut-fin, si_fermer_quota-quota-date_debut-date_fin]),
	writeln(fermeture2-Class),
	all(Class, name, [contrat-personne = Personne, DateFinAttr > Date], [], Objs),
	$member(Obj, Objs),
	(Obj@DateDebutAttr =< Date ->
	    Goal=..[Class, Obj, set_atts([DateFinAttr <- Date])]
	;
	    Goal=..[Class, Obj, destroy]
	),
	call(Goal),
	fail.
% Rôle Web 
personne_fermeture_elements(Personne, Date, si_fermer_role_web):-
	writeln(fermeture3),
	all(web_role_personne, name, [personne = Personne, date_fin > Date], [], Objs0),
	all(web_role_utilisateur, name, [utilisateur-numero_matricule = Personne@numero_matricule, date_fin > Date], Objs0, Objs),
	$member(Obj, Objs),
	(Obj@date_debut =< Date ->
	    Goal=..[Obj@class, Obj, set_atts([date_fin <- Date])]
	;
	    Goal=..[Obj@class, Obj, destroy]
	),
	call(Goal),
	fail.	    
% Personne
personne_fermeture_elements(Personne, Date, si_fermer_personne):-
	writeln(fermeture4),
	personne(Personne, set_atts([date_sortie_societe <- Date])),
	!.
% Planning
personne_fermeture_elements(Personne, Date, si_desaffecter_planning):-
	writeln(desaffectation),
	DateD is Date + 1440,
	
	%% Etape 1: Mémorisation de la personne et de la date de sortie
	%% -> En vue de la suppression et désaffectation des activités en base (non chargées en mémoire)
	
	assert(personne_buffer_suppression_desaffectation_db(Personne@db_key, Date)),

	%% Etape 2: Suppression et désaffectation des objets en mémoire


	% On récupère les activités débutant au moins à partir du lendemain de la date de sortie
	personne(Personne, get_planning(DateD, mode@end_date, [], Planning)),
	all(marqueur, name, [ressource = Personne, date >= DateD, date =< mode@end_date], Planning, Activites_List),
	$member(Activite, Activites_List),

	mode@update_gui <<- off,

	($member(Activite@class, [indispo_planif, marqueur, doublure, doublure_etiquette]) ->
	    % Appel volontaire destroy sans passer par le can_destroy
	    % Fonctionnalité reservé aux experts
	    Goal=..[Activite@class, Activite, destroy]
	;
	    personne_fermeture_elements_desaffecter(Activite@class, Activite, Goal)
	),
	call(Goal),

	change_view(mode@view),
	fail.
% Demandes de congés
personne_fermeture_elements(Personne, Date, si_annuler_demandes_conges):-
	writeln(annulation_conges),
	all(demande_conges, name, [personne = Personne, date_debut >= Date, date_fin >= Date], [], DCs),
	$member(DC, DCs),
	DC@etat_planificateur <- '3',
	DC@etat_demandeur <- '3',      
	sprintf(Date_Etat, "date_etat_%s", ['3']),
	sprintf(User_Etat, "user_etat_%s", ['3']),
	get_prolog_flag(date, Date_Term),
	date_convert(Date_Term, Date),
	DC@Date_Etat <- Date,
	DC@User_Etat <- mode@user,
	modify_change(DC),
	fail.
personne_fermeture_elements(Personne, Date, Element).

% On donne en argument le db_key de la personne et la nouvelle date de sortie
personne_suppression_desaffectation_db(Personne, Date):-
	db_connected,
	DateD is Date + 1440,
	db_command("DELETE from OPTI_INDISPO_PLANIF WHERE RESSOURCE=%s AND DATE_DEBUT >= chip2ora(%s)", [Personne, DateD]),

	db_command("UPDATE OPTI_TABLE_LOG SET DATE_LAST_DELETE = SYSDATE WHERE TABLE_NAME = 'OPTI_INDISPO_PLANIF'");
    
        db_command("DELETE from OPTI_MARQUEUR WHERE RESSOURCE=%s AND OPTI_DATE >= chip2ora(%s)", [Personne, DateD]),

        db_command("DELETE from OPTI_DOUBLURE 
                    WHERE OPTI_DOUBLURE.DB_KEY IN (SELECT OPTI_DOUBLURE.DB_KEY FROM OPTI_DOUBLURE,OPTI_TACHE WHERE OPTI_DOUBLURE.TACHE=OPTI_TACHE.DB_KEY 
		                     AND OPTI_DOUBLURE.RESSOURCE=%s AND OPTI_TACHE.JOUR_PLANIFIE >= chip2ora(%s))", [Personne, DateD]),

	db_command("DELETE from OPTI_DOUBLURE_ETIQUETTE WHERE PERSONNE=%s AND JOUR_PLANIF >= chip2ora(%s)", [Personne, DateD]),	

        %db_command("UPDATE OPTI_TABLE_LOG SET DATE_LAST_INSERT = SYSDATE, DATE_LAST_DELETE = SYSDATE WHERE TABLE_NAME = 'OPTI_INDISPO_PLANIF'")
	fail.
personne_suppression_desaffectation_db(Personne, Date):-
	db_connected,
	DateD is Date + 1440,
	date_now(_,Time_stamp),
	db_command("UPDATE OPTI_VACATION_T SET LAST_USER = substr('%s', 6), TIME_STAMP = chip2ora(%s), RESSOURCE = substr('0', 11) 
		    WHERE RESSOURCE=%s AND JOUR_PLANIFIE >= chip2ora(%s)", [mode@user, Time_stamp, Personne, DateD]),
	
	db_command("UPDATE OPTI_ETIQUETTE SET OPTI_ETIQUETTE.TIME_STAMP = chip2ora(%s),
	                                      OPTI_ETIQUETTE.PERSONNE = substr('0', 11) 
		    WHERE PERSONNE=%s AND JOUR_PLANIF >= chip2ora(%s)", [Time_stamp, Personne, DateD]),

	db_command("UPDATE OPTI_TABLE_LOG SET DATE_LAST_UPDATE = SYSDATE WHERE TABLE_NAME = 'OPTI_ETIQUETTE'");

		writeln('ICIIII'),


	db_command("UPDATE OPTI_TACHE_CYCLIQUE SET OPTI_TACHE_CYCLIQUE.LAST_USER = substr('%s', 6), 
	                                           OPTI_TACHE_CYCLIQUE.TIME_STAMP = chip2ora(%s), 
						   OPTI_TACHE_CYCLIQUE.RESSOURCE = substr('0', 11) 
		    WHERE RESSOURCE=%s AND JOUR_PLANIFIE >= chip2ora(%s)", [mode@user, Time_stamp, Personne, DateD]),
	
	% AJOUTER RESSOURCE BESOIN
	db_command("UPDATE OPTI_TACHE SET OPTI_TACHE.LAST_USER = substr('%s', 6),
	                                  OPTI_TACHE.RESSOURCE = SUBSTR('0', 11),
                                          OPTI_TACHE.TIME_STAMP = chip2ora(%s)
		    WHERE RESSOURCE=%s AND JOUR_PLANIFIE >= chip2ora(%s)", [mode@user, Time_stamp, Personne, DateD]),

% UPDATE OPTI_TABLE_LOG SET DATE_LAST_INSERT = SYSDATE, DATE_LAST_DELETE = SYSDATE WHERE TABLE_NAME = 'OPTI_INDISPO_PLANIF';

	fail.
personne_suppression_desaffectation_db(Personne, Date):-
	retractall(personne_buffer_suppression_desaffectation_db(_,_)).

% Methode pour recherche du planning en base:
% On regarde s'il y a au moins une activité planifiée après Date
personne_search_planning(Personne, Date, Planning_db):-
	db_connected,
	DateD is Date + 1440,
	
	once(mu_db_tuple("select db_key from OPTI_INDISPO_PLANIF WHERE RESSOURCE=%s AND DATE_DEBUT >= chip2ora(%s)
                          UNION
		          select db_key from OPTI_MARQUEUR WHERE RESSOURCE=%s AND OPTI_DATE >= chip2ora(%s)
		          UNION
		          select db_key from OPTI_VACATION_T WHERE RESSOURCE=%s AND JOUR_PLANIFIE >= chip2ora(%s)
		          UNION
		          select OPTI_DOUBLURE.db_key from OPTI_DOUBLURE, OPTI_TACHE WHERE OPTI_DOUBLURE.TACHE=OPTI_TACHE.DB_KEY 
		                                                       AND OPTI_DOUBLURE.RESSOURCE=%s AND OPTI_TACHE.JOUR_PLANIFIE >= chip2ora(%s)
			  UNION
		          select db_key from OPTI_TACHE WHERE RESSOURCE=%s AND JOUR_PLANIFIE >= chip2ora(%s)
		          UNION
		          select db_key from OPTI_TACHE_CYCLIQUE WHERE RESSOURCE=%s AND JOUR_PLANIFIE >= chip2ora(%s)
			  UNION
		          select db_key from OPTI_DOUBLURE_ETIQUETTE WHERE PERSONNE=%s AND JOUR_PLANIF >= chip2ora(%s)
			  UNION
		          select db_key from OPTI_ETIQUETTE WHERE PERSONNE=%s AND JOUR_PLANIF >= chip2ora(%s)", 
		         [Personne, DateD, Personne, DateD, Personne, DateD, Personne, DateD, 
			  Personne, DateD, Personne, DateD, Personne, DateD, Personne, DateD], Planning_db)),

	!.
	
 
/*******************************************************************************
* Desaffectation des tache, tache_cyclique, vacation_t et etiquette
*******************************************************************************/
personne_fermeture_elements_desaffecter(tache, Tache, Goal):- 
	Goal=..[besoin, Tache@besoin, set_atts([ressource <- 0])].
personne_fermeture_elements_desaffecter(tache_cyclique, Tache_c, Goal):-
	Goal=..[tache_cyclique, Tache_c, unassign].
personne_fermeture_elements_desaffecter(vacation_t, Vacation, Goal):-
	Goal=..[vacation_t, Vacation, unassign].
personne_fermeture_elements_desaffecter(etiquette, Etiquette, Goal):-
	Goal=..[etiquette, Etiquette, set_atts([personne <- 0])].





/*******************************************************************************
* Retourne les indisponibilités contractuelles ou les souhaits de travail
*
* personne(+R, get_indisponibilies(+From, +To, -I, -Debut, -Fin)):
* 
* ATTENTION:
*            Prédicat Back-trackant
*******************************************************************************/
% Cas 1 : disponibilities basées les préférences de la fiche personne
personne(R, get_indisponibilies(From, To, Debut, Fin)):-
	specific_parameter(disponibilities, personne),
	From0 is From/1440,
	To0 is To/1440 + 1,
	From1 is 1,
	To1 is (To0 - From0) + 1,

	I :: From1..To1, 
	indomain(I),

	Date is ((I-1)+From0)*1440,
	date_day_of_week(Date, Weekday),

	$is_member_of(Day-Value, [lundi-0, mardi-1, mercredi-2, jeudi-3, vendredi-4, samedi-5, dimanche-5]),
	sprintf(Flag_Attr, "si_%s", [Day]),

        R@Flag_Attr = '1',

	sprintf(From_Attr, "%s_heure_debut", [Day]),
	sprintf(To_Attr, "%s_heure_fin", [Day]),

        (Debut is Date,
         Fin is Date + R@From_Attr     
     ;
	 Debut is Date + R@To_Attr,
         Fin is Date + 1440
        ).
% Cas 2 : disponibilities basées les disponibilités contractuelles
personne(R, get_indisponibilies(From, To, Debut, Fin)):-	
	specific_parameter(disponibilities, dispo_contractuelle),
	!,
	dispo_contractuelle(R, get_indispo(From, To, Plages_Indispo)),
	$member(t(Debut, Fin), Plages_Indispo).
	
	




% Donne l'age d'une personne selon le jour courant
personne(P, get_age(Age)):-
	get_prolog_flag(date, date(NYear, NMonth, NDay, _, _, _)),
	date_convert(date(NYear, NMonth, NDay, 0, 0, 0), Now),
	personne(P, get_age(Now, Age)).

% Donne l'age d'une personne selon une date de référence
personne(P, get_age(Date_Ref, Age)):-
	date_convert(date(NYear, NMonth, NDay, _, _, _), Date_Ref),
	date_convert(date(PYear, PMonth, PDay, _, _, _), P@date_naissance),

	Nb_Annees is NYear - PYear,

	% Date d'anniversaire dans l'année
	date_convert(date(NYear, PMonth, PDay, 0, 0, 0), Date_Anniversaire),

	% Date d'anniversaire future, retire 1 à l'âge
	(Date_Anniversaire > Date_Ref ->
	    Age is Nb_Annees - 1
	;
	    Age is Nb_Annees
	).







% End Of File %


