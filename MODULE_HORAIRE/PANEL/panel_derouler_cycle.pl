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
* Pred specifics
*******************************************************************************/
?- util_declare(specific_derouler_cycle_after_action(0, 0), fail).

?- util_declare(specific_panel_derouler_cycle_t_items(0), fail).
?- util_declare(specific_derouler_cycle_post_traitement).
?- util_declare(specific_panel_derouler_cycle_t_canevas_changed(_), true).
?- util_declare(specific_derouler_cycle_t_after_build_one_occurence(As, Ps, From, Min, Max, Canevas, Amplitude, Id, Parameters, Rotation_Atts, Si_Remplacement), fail).
?- util_declare(specific_panel_derouler_cycle_t_after_open_callback, fail).


/*******************************************************************************
% PART I
*
*
%            PANEL DE DEROULEMENT
*
*
*
*******************************************************************************/
/*******************************************************************************
* Ouverture du panel
*******************************************************************************/
derouler_cycle(open_panel):-
	derouler_cycle_t(open_panel).

derouler_cycle_t(open_panel):-
	util_create_and_open_dialog(panel_derouler_cycle_t, panel_derouler_cycle_t_init_callback, panel_derouler_cycle_t_open_callback, none).
	

% initialisation du date du panel par la date du premier lundi
panel_derouler_cycle_t_init_callback:-
	text2(panel_derouler_cycle_t_amplitude, passive),
	text2(panel_derouler_cycle_t_personnes, passive),
        text2(panel_derouler_cycle_t_lignes, passive),
	%text2(panel_derouler_cycle_t_canevas_t, passive),
	%text2(panel_derouler_cycle_t_equipe, passive),
	text2(panel_derouler_cycle_t_occurence, select(1)),

	appl_get_loading_period(DebutPeriode, _),
	From0 is DebutPeriode + 6*1440,

	julian_monday_of_week(From0, From),
	text2(panel_derouler_cycle_t_depart, select(From)),
	text2(panel_derouler_cycle_t_depart_ref, select(From)),
	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_depart, From),
	(specific_parameter(default_rotation_ligne, off) ->
	    Si_Rotation = off
	;
	    Si_Rotation = on
	),
	switch(panel_derouler_cycle_rotation, select(Si_Rotation)),
	panel_derouler_cycle_t_changed(panel_derouler_cycle_t, panel_derouler_cycle_rotation, Si_Rotation),

	switch(panel_derouler_cycle_t_deroulement_personne, select(off)),
	text2(panel_derouler_cycle_t_personne, unmap),

	switch(panel_derouler_cycle_si_full_amplitude, current(Si_Full_Amplitude)),
	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_si_full_amplitude, Si_Full_Amplitude),
	text2(panel_derouler_cycle_t_depart_ref, passive),
	text2(panel_derouler_cycle_t_fin_ref, passive),
	true.


% ouverture du panel
panel_derouler_cycle_t_open_callback:-
	text2(panel_derouler_cycle_t_depart, current(From)),
	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_depart, From),
	fail.
panel_derouler_cycle_t_open_callback:-
	panel_derouler_cycle_init_last_roulement,
	fail.
% ré-initalise le champ "Lignes"
panel_derouler_cycle_t_open_callback:-
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	instance(Canevas),
	text2(panel_derouler_cycle_t_lignes, select(Canevas@nb_lignes)),
	fail.
% ré-initalise le champ "Equipe" 
panel_derouler_cycle_t_open_callback:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	instance(Equipe),
	%
	(appl_mode_planif(heure) ->
	    % Technicien
	    [Class_Appart_Equipe, Class_Equipe] = [appart_cycle_t, equipe_cycle_t]
	;
	    % Journaliste
	    [Class_Appart_Equipe, Class_Equipe] = [appart_equipe_cycle, equipe_cycle]
	),
	panel_derouler_equipe_cycle(Equipe, get_nb_personnes(Nb_AECs)),
	text2(panel_derouler_cycle_t_personnes, select(Nb_AECs)),
	fail.
% ré-initalise le champ "Personnes" 
panel_derouler_cycle_t_open_callback:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(on)),
	text2(panel_derouler_cycle_t_personne, current(Personne)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	(instance(Personne) ->
	    text2(panel_derouler_cycle_t_personnes, select(1))
	;
	    (instance(Canevas@type_contrat) ->
		text2(panel_derouler_cycle_t_personne, contents(Personnes)),
		util_length(Personnes, Nb_Personnes0),
		Nb_Personnes is Nb_Personnes0 -1,
		text2(panel_derouler_cycle_t_personnes, select(Nb_Personnes))
	    ;
		text2(panel_derouler_cycle_t_personnes, select(0))		
	    )
	),
	fail.
% Passive et désactive le champ Besoins si interdiction de dérouler sur un équipe incomplète
panel_derouler_cycle_t_open_callback:-
	switch(panel_derouler_cycle_t_besoin, active),
	specific_parameter(derouler_cycle_check_nb_personnes, alert2),
	switch(panel_derouler_cycle_t_besoin, select(off)),
	switch(panel_derouler_cycle_t_besoin, passive),
	fail.
% Module Jour : Autorisation des etiquettes non affectées
panel_derouler_cycle_t_open_callback:-
	appl_mode_planif(jour),
	not specific_parameter(etiquette_non_affecte, on),
	switch(panel_derouler_cycle_t_besoin, select(off)),
	switch(panel_derouler_cycle_t_besoin, passive),
	fail.
panel_derouler_cycle_t_open_callback:-
	switch(panel_derouler_cycle_rotation, current(Flag)),
	panel_derouler_cycle_t_changed(panel_derouler_cycle_t, panel_derouler_cycle_rotation, Flag),
	fail.
panel_derouler_cycle_t_open_callback:-
	panel_derouler_cycle_t_after_open_callback,
	fail.
panel_derouler_cycle_t_open_callback. 

/*******************************************************************************
*
*******************************************************************************/
panel_derouler_cycle_t_after_open_callback:-
	specific_panel_derouler_cycle_t_after_open_callback,
	!.
panel_derouler_cycle_t_after_open_callback.


/*******************************************************************************
* Renvoie les éléments spécifiques
*******************************************************************************/
panel_derouler_cycle_t_get_specific_items(Specific_Items):-
	specific_panel_derouler_cycle_t_items(Specific_Items),
	!.
panel_derouler_cycle_t_get_specific_items([]).




/*******************************************************************************
* Redirection vers le message technicien ou journaliste
*******************************************************************************/
% Pour les canevas
panel_derouler_canevas(Canevas, Msg):-
	appl_mode_planif(heure),
	!,
	canevas_t(Canevas, Msg).
panel_derouler_canevas(Canevas, Msg):-
	appl_mode_planif(jour),
	!,
	canevas(Canevas, Msg).

% Pour les équipes
panel_derouler_equipe_cycle(Equipe, Msg):-
	appl_mode_planif(heure),
	!,
	equipe_cycle_t(Equipe, Msg).
panel_derouler_equipe_cycle(Equipe, Msg):-
	appl_mode_planif(jour),
	!,
	equipe_cycle(Equipe, Msg).

% Pour les roulements
panel_derouler_roulement_cycle(Roulement, Msg):-
	appl_mode_planif(heure),
	!,
	roulement_cycle_t(Roulement, Msg).
panel_derouler_roulement_cycle(Roulement, Msg):-
	appl_mode_planif(jour),
	!,
	roulement_cycle(Roulement, Msg).

% Pour les generator
panel_derouler_generator_cycle(Generator, Msg):-
	appl_mode_planif(heure),
	!,
	generator_cycle_t(Generator, Msg).
panel_derouler_generator_cycle(Generator, Msg):-
	appl_mode_planif(jour),
	!,
	generator_cycle(Generator, Msg).

/*******************************************************************************
* Initialise la date du dernier roulement
*******************************************************************************/
% Mode équipe
panel_derouler_cycle_init_last_roulement:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	switch(panel_derouler_cycle_rotation, current(Si_Rotation)),

	% Le roulement précédant est complete
	panel_derouler_canevas(Canevas, get_last_roulement(Equipe, Last_R)),
	Canevas@nb_lignes > 0,
	Last_R@date_fin = Last_R@date_fin_roulement,
	Last_Roulement is Last_R@date_fin,
	!,
	switch(panel_derouler_cycle_si_full_amplitude, select(on)),
	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_si_full_amplitude, on),

	mu_date_make_atom(Last_Roulement, date2, Last_Roulement_Atom),
	text2(panel_derouler_date, select(Last_Roulement_Atom)),
	From is Last_Roulement+1440,
	panel_derouler_canevas(Canevas, get_next_ligne(Equipe, Next_Ligne)),

	(Si_Rotation = on ->
	    Taille = Canevas@nb_lignes,
	    Next_Ligne1 is mod(Next_Ligne, Taille) + 1,
	    text2(panel_derouler_cycle_t_ligne, select(Next_Ligne1))
	;
	    % N'incrémente pas le numéro de premiere ligne si non cyclique
	    text2(panel_derouler_cycle_t_ligne, select(Next_Ligne))
	),
	text2(panel_derouler_cycle_t_depart, select(From)),
	text2(panel_derouler_cycle_t_depart_ref, select(From)),
	text2(panel_derouler_cycle_t_numero_jour, select(1)),
	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_depart, From).

panel_derouler_cycle_init_last_roulement:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	switch(panel_derouler_cycle_rotation, current(Si_Rotation)),
	text2(panel_derouler_cycle_t_occurence, current(Occurence)),

	% Le roulement précédant n'est pas complete
	panel_derouler_canevas(Canevas, get_last_roulement(Equipe, Last_R)),
	Last_R@date_fin \= Last_R@date_fin_roulement,
	Last_Roulement is Last_R@date_fin,
	!,
	switch(panel_derouler_cycle_si_full_amplitude, select(off)),
	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_si_full_amplitude, off),

	mu_date_make_atom(Last_Roulement, date2, Last_Roulement_Atom),
	text2(panel_derouler_date, select(Last_Roulement_Atom)),
	panel_derouler_canevas(Canevas, get_current_ligne(Equipe, Current_Ligne)),

        % N'incrémente pas le numéro de premiere ligne si non cyclique
        text2(panel_derouler_cycle_t_ligne, select(Current_Ligne)),

	From is Last_R@date_fin + 1440,
	text2(panel_derouler_cycle_t_depart, select(From)),
	From_Ref is Last_R@date_debut_roulement,
	text2(panel_derouler_cycle_t_depart_ref, select(From_Ref)),

	To is Last_R@date_fin_roulement,
	text2(panel_derouler_cycle_t_fin, select(To)),

	To_Ref is Last_R@date_fin_roulement,
	text2(panel_derouler_cycle_t_fin_ref, select(To_Ref)),

	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_occurence, Occurence),

	No_Jour is Canevas@longueur - (Last_R@date_fin_roulement - Last_R@date_fin)/1440 + 1,
	text2(panel_derouler_cycle_t_numero_jour, select(No_Jour)),

%	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_si_full_amplitude, off),

        true.


% Mode personne
panel_derouler_cycle_init_last_roulement:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(on)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	text2(panel_derouler_cycle_t_personne, current(Personne)),
	switch(panel_derouler_cycle_rotation, current(Si_Rotation)),
	
	panel_derouler_canevas(Canevas, get_last_roulement_date_personne(Personne, Last_Roulement)),
	Canevas@nb_lignes > 0,
	!,
	mu_date_make_atom(Last_Roulement, date2, Last_Roulement_Atom),
	text2(panel_derouler_date, select(Last_Roulement_Atom)),
	From is Last_Roulement+1440,
	panel_derouler_canevas(Canevas, get_next_ligne_personne(Personne, Next_Ligne)),
	(Si_Rotation = on ->
	    Taille = Canevas@nb_lignes,
	    Next_Ligne1 is mod(Next_Ligne, Taille) + 1,
	    text2(panel_derouler_cycle_t_ligne, select(Next_Ligne1))
	;
	    text2(panel_derouler_cycle_t_ligne, select(Next_Ligne))
	),
	text2(panel_derouler_cycle_t_depart, select(From)),
	text2(panel_derouler_cycle_t_depart_ref, select(From)),
	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_depart, From).
panel_derouler_cycle_init_last_roulement:-
	switch(panel_derouler_cycle_si_full_amplitude, select(on)),
	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_si_full_amplitude, on),

	text2(panel_derouler_date, select('-')),
%	From is mode@start_date + 7*1440,
	text2(panel_derouler_cycle_t_ligne, select(1)),
	(appl_mode_planif(heure) ->
	    % Technicien
	    From0 is mode@start_date + 6*1440
	;
	    % Journaliste
	    From0 is jour_parameter@jour_j
	), 
	julian_monday_of_week(From0, From),
	text2(panel_derouler_cycle_t_depart, select(From)),
	text2(panel_derouler_cycle_t_depart_ref, select(From)),
	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_depart, From).






/*******************************************************************************
* Callback Boutons
*******************************************************************************/
panel_derouler_cycle_t_pressed(_, panel_derouler_cycle_t_ok):-
	panel_derouler_cycle,
	fail.
panel_derouler_cycle_t_pressed(_, panel_derouler_cycle_t_ok):-
	!.


/*******************************************************************************
* Etend temporairement end_date si le roulement se trouve en dehors
* et que cela est authorisé
*******************************************************************************/
panel_derouler_cycle_should_extend_end:-
	% Authorisation de dérouler en dehors
	not specific_parameter(check_canevas_in_period, on),
	!,
	text2(panel_derouler_cycle_t_depart_ref, current(From)),
	text2(panel_derouler_cycle_t_fin_ref, current(To)),
%	system(cls),
	To2 is max(To, mode@end_date),
	mode@end_date <<- To2,
	mu_date(mode@end_date),
        % PC 17/06/2014 Ajout de specific_parameter(check_canevas_in_period, on)
        % jour_parameter@check_obj_in_periode ne semble
	% jour_parameter@check_obj_in_periode <- no
	true.
panel_derouler_cycle_should_extend_end:-
	!.


/*******************************************************************************
* DEROULEMENT
*******************************************************************************/
% Charge le planning complémentaire si l'option est active
panel_derouler_cycle:-
	panel_derouler_cycle_download_extra_planning,
	fail.
% Fait un controle sur les paramètres
panel_derouler_cycle:-
	panel_derouler_cycle_should_extend_end,
	not panel_derouler_cycle_t_check_panel,
	!.

% LOCK DE CYCLE, s'arrête là sinon
panel_derouler_cycle:-
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	(appl_mode_planif(heure) ->
	    not canevas_t(Canevas, lock)
	;
	    not canevas(Canevas, lock)
	),
	!,
	fail.
% Implémente le roulement
panel_derouler_cycle:-
	text2(panel_derouler_generateur_cycle_t, current(Generateur)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	anyway(derouler_cycle_t),

	% post traitement
	anyway(specific_derouler_cycle_post_traitement),
	
	true.


/*******************************************************************************
*
*******************************************************************************/
% VÉRIFICATION
panel_derouler_cycle_t_pressed(_, panel_derouler_cycle_t_check):-
	panel_derouler_cycle_t_check_panel,
	fail.
panel_derouler_cycle_t_pressed(_, panel_derouler_cycle_t_check).


% Nettoyage de planning un cycle
panel_derouler_cycle_t_pressed(panel_derouler_cycle_t, panel_derouler_cycle_t_clean):-
	text2(panel_derouler_cycle_t_canevas_t, current(Generateur_Cycle_t)),
	not instance(Generateur_Cycle_t),
	!,
	alert('Action impossible : aucun générateur de cycle n''est sélectionné.', [text@abort], Answer),
	fail.
panel_derouler_cycle_t_pressed(panel_derouler_cycle_t, panel_derouler_cycle_t_clean):-
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	(appl_mode_planif(heure) ->
	    not canevas_t(Canevas, lock)
	;
	    not canevas(Canevas, lock)
	),
	!,
	fail.
panel_derouler_cycle_t_pressed(panel_derouler_cycle_t, panel_derouler_cycle_t_clean):-
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	switch(panel_derouler_cycle_t_deroulement_personne, current(Si_Personne)),
	(Si_Personne = off ->
	    Ressource = '-',
	    text2(panel_derouler_cycle_t_equipe, current(Equipe))
	;
	    Equipe = '-',
	    text2(panel_derouler_cycle_t_personne, current(Ressource))
	),
	panel_supprimer_roulement_cycle(open(Canevas, Equipe, Ressource)).

% Fermeture
panel_derouler_cycle_t_pressed(_, panel_derouler_cycle_t_cancel):-
	window_current(panel_derouler_cycle_t),
	window_op(unmap).



/*******************************************************************************
* Callback Saisies
*******************************************************************************/
panel_derouler_cycle_t_changed(_, Item, _):-
	not member(Item, [panel_derouler_cycle_t_depart, panel_derouler_cycle_t_fin, panel_derouler_cycle_t_occurence,
	                  panel_derouler_cycle_t_ligne, panel_derouler_cycle_rotation, 
			  panel_derouler_cycle_si_full_amplitude, panel_derouler_cycle_t_numero_jour]),
	panel_derouler_cycle_init_last_roulement,
	fail.
% Déroulement sur des amplitudes pleines ou non
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_si_full_amplitude, Si_Full_Amplitude):-
	!,
	(Si_Full_Amplitude = on ->
	    text2(panel_derouler_cycle_t_numero_jour, select(1)),
	    text2(panel_derouler_cycle_t_depart_ref, current(Debut_Ref)),
	    text2(panel_derouler_cycle_t_depart, select(Debut_Ref)),
	    text2(panel_derouler_cycle_t_fin_ref, current(Fin_Ref)),
	    text2(panel_derouler_cycle_t_fin, select(Fin_Ref)),
	    text2(panel_derouler_cycle_t_numero_jour, passive),
	    text2(panel_derouler_cycle_t_fin, passive)
	;
	    text2(panel_derouler_cycle_t_numero_jour, active),
	    text2(panel_derouler_cycle_t_fin, active)
	    %panel_derouler_cycle_init_last_roulement
	).
% Changement de N° de jour de départ
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_numero_jour, No_Jour):-
	!,
	text2(panel_derouler_cycle_t_depart_ref, current(From)),
	From2 is From + (No_Jour-1)*1440,
	text2(panel_derouler_cycle_t_depart, select(From2)).
	    
% Saisie d'une date
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_depart, Date):-
	switch(panel_derouler_cycle_si_full_amplitude, current(Si_Full_Amplitude)),
	Si_Full_Amplitude = off,
	!,
	text2(panel_derouler_cycle_t_depart_ref, current(From)),
	No_Jour is (Date-From)/1440 + 1,
	text2(panel_derouler_cycle_t_numero_jour, select(No_Jour)).
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_depart, Date):-
	% Je ne touche pas à la date de début et de fin si:
	% si (Si_Amplitude = off)
	% et si (New_Debut_Ref + N° Jour < Fin),   
	switch(panel_derouler_cycle_si_full_amplitude, current(Si_Full_Amplitude)),
	Si_Full_Amplitude = on,
	!,
	(specific_parameter(start_cycle_on_monday, on) ->
	    julian_monday_of_week(Date, Debut)
	;
	    Date = Debut),

	text2(panel_derouler_cycle_t_amplitude, current(Longueur)),
	text2(panel_derouler_cycle_t_occurence, current(Occurences)),

	text2(panel_derouler_cycle_t_depart, select(Debut)),
	text2(panel_derouler_cycle_t_depart_ref, select(Debut)),
	Fin is Debut + Occurences*1440*Longueur - 1440,
%	writeln(1-Fin is Debut + Occurences*1440*Longueur),
	text2(panel_derouler_cycle_t_fin, select(Fin)),
	text2(panel_derouler_cycle_t_fin_ref, select(Fin)).

% Changement du nombre d'occurence
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_occurence, Occurences):-
	!,
	text2(panel_derouler_cycle_t_depart_ref, current(Debut)),
	text2(panel_derouler_cycle_t_amplitude, current(Longueur)),
	Fin is Debut + Occurences*1440*Longueur - 1440,
%	writeln(2-Fin is Debut + Occurences*1440*Longueur),
	text2(panel_derouler_cycle_t_fin, select(Fin)),
	text2(panel_derouler_cycle_t_fin_ref, select(Fin)).

% Change de la date de fin
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_fin, Date):-
	switch(panel_derouler_cycle_si_full_amplitude, current(Si_Full_Amplitude)),
	Si_Full_Amplitude = off,
	!.
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_fin, Date):-
	switch(panel_derouler_cycle_si_full_amplitude, current(Si_Full_Amplitude)),
	Si_Full_Amplitude = on,
	!,
	(specific_parameter(start_cycle_on_monday, on) ->
	    julian_monday_of_week(Date, Fin0),
	    Fin is Fin0-1440
	;
	    Fin is Date),
	text2(panel_derouler_cycle_t_fin, select(Fin)),
	text2(panel_derouler_cycle_t_fin_ref, select(Fin)),
	text2(panel_derouler_cycle_t_amplitude, current(Longueur)),
	text2(panel_derouler_cycle_t_occurence, current(Occurences)),
	Debut is Fin - Occurences*1440*Longueur + 1440,
%	writeln(3-Debut is Fin - Occurences*1440*Longueur),
	text2(panel_derouler_cycle_t_depart, select(Debut)),
	text2(panel_derouler_cycle_t_depart_ref, select(Debut)).


% Sélection d'un generateur de cycle
panel_derouler_cycle_t_changed(_, panel_derouler_generateur_cycle_t, Generateur_Cycle_t):-
	not instance(Generateur_Cycle_t),
	!,
	text2(panel_derouler_date, select('-')),
	text2(panel_derouler_cycle_t_canevas_t, select('?')),
	text2(panel_derouler_cycle_t_equipe, select('?')),
	text2(panel_derouler_cycle_t_lignes, select(0)),
	text2(panel_derouler_cycle_t_personnes, select(0)),
	text2(panel_derouler_cycle_t_amplitude, select(0)),
	text2(panel_derouler_cycle_t_occurence, select(1)),
	switch(panel_derouler_cycle_rotation, select(off)).

panel_derouler_cycle_t_changed(_, panel_derouler_generateur_cycle_t, Generateur_Cycle_t):-
	instance(Generateur_Cycle_t),
	!,
	(appl_mode_planif(heure) ->
	    % Technicien
	    Canevas = Generateur_Cycle_t@canevas_t,
	    [Class_Appart_Equipe, Class_Equipe] = [appart_cycle_t, equipe_cycle_t]
	;
	    % Journaliste
	    Canevas = Generateur_Cycle_t@canevas,
	    [Class_Appart_Equipe, Class_Equipe] = [appart_equipe_cycle, equipe_cycle]
	),

	% Le champ si_rotation
	once($member(Generateur_Cycle_t@si_rotation-Switch, ['0'-off, '1'-on])),
	switch(panel_derouler_cycle_rotation, select(Switch)),

	text2(panel_derouler_cycle_t_canevas_t, select(Canevas)),
	text2(panel_derouler_cycle_t_lignes, select(Canevas@nb_lignes)),
	text2(panel_derouler_cycle_t_amplitude, select(Canevas@longueur)),
	(integer(Generateur_Cycle_t@nb_occurence) ->
	    text2(panel_derouler_cycle_t_occurence, select(Generateur_Cycle_t@nb_occurence))
	;
	    text2(panel_derouler_cycle_t_occurence, select(1))
	),

	Equipe = Generateur_Cycle_t@Class_Equipe,
	panel_derouler_equipe_cycle(Equipe, get_nb_personnes(Nb_AECs)),
	text2(panel_derouler_cycle_t_equipe, select(Equipe)),
	text2(panel_derouler_cycle_t_personnes, select(Nb_AECs)),
	switch(panel_derouler_cycle_t_deroulement_personne, select(off)),
	text2(panel_derouler_cycle_t_equipe, open),
	text2(panel_derouler_cycle_t_personne, unmap),

	panel_derouler_cycle_init_last_roulement,
	specific_panel_derouler_cycle_t_canevas_changed(Canevas),
        true.


% Sélection d'un canevas
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_canevas_t, Canevas):-
	text2(panel_derouler_generateur_cycle_t, select('?')),
	fail.
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_canevas_t, Canevas):-
	panel_derouler_cycle_t_personne@unused <- '?',
	instance(Canevas@type_contrat),
	panel_derouler_cycle_t_personne@unused <- 'Toutes (selon le Contrat)',
	fail.
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_canevas_t, Canevas):-
	text2(panel_derouler_cycle_t_personne, select(panel_derouler_cycle_t_personne@unused)),
	fail.
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_canevas_t, Canevas):-
	instance(Canevas),
	!,
	text2(panel_derouler_cycle_t_lignes, select(Canevas@nb_lignes)),
	text2(panel_derouler_cycle_t_amplitude, select(Canevas@longueur)),
	text2(panel_derouler_cycle_t_depart, current(Date)),
	panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_depart, Date),
	% Le champ si_rotation
	once($member(Canevas@si_rotation-Switch, ['0'-off, '1'-on])),
	switch(panel_derouler_cycle_rotation, select(Switch)),
	specific_panel_derouler_cycle_t_canevas_changed(Canevas).
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_canevas_t, Canevas):-

	not instance(Canevas),
	!,
	text2(panel_derouler_cycle_t_lignes, select(0)),
	text2(panel_derouler_cycle_t_amplitude, select(0)),
	specific_panel_derouler_cycle_t_canevas_changed(Canevas).




% Selection d'une équipe
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_equipe, Equipe):-
	text2(panel_derouler_generateur_cycle_t, select('?')),
	fail.
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_equipe, Equipe):-
	instance(Equipe),
	!,
	panel_derouler_equipe_cycle(Equipe, get_nb_personnes(Nb_Ps)),
	text2(panel_derouler_cycle_t_personnes, select(Nb_Ps)).
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_equipe, Equipe):-	
	not instance(Equipe),	
	!,
	text2(panel_derouler_cycle_t_personnes, select(0)).

% Selection d'une personne
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_personne, Personne):-
	text2(panel_derouler_generateur_cycle_t, select('?')),
	fail.
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_personne, Personne):-
	instance(Personne),
	!,
	text2(panel_derouler_cycle_t_personnes, select(1)).
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_personne, Personne):-	
	not instance(Personne),	
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	instance(Canevas@type_contrat),
	!,
	text2(panel_derouler_cycle_t_personne, contents(Personnes)),
	util_length(Personnes, Nb_Personnes0),
	Nb_Personnes is Nb_Personnes0 -1,
	text2(panel_derouler_cycle_t_personnes, select(Nb_Personnes)).
panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_personne, Personne):-
	not instance(Personne),
	!,
	text2(panel_derouler_cycle_t_personnes, select(0)).

% Ligne de départ
panel_derouler_cycle_t_changed(panel_derouler_cycle_t, panel_derouler_cycle_t_ligne, _):-
	!.

% Rotation des lignes
panel_derouler_cycle_t_changed(panel_derouler_cycle_t, panel_derouler_cycle_rotation, Flag):-
	panel_derouler_cycle_init_last_roulement.
% panel_derouler_cycle_t_changed(panel_derouler_cycle_t, panel_derouler_cycle_rotation, Flag):-
% 	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
% 	(Flag = on ->
% 	    text2(panel_derouler_cycle_t_ligne, active),
% 	    panel_derouler_cycle_init_last_roulement
% 	;
% 	    text2(panel_derouler_cycle_t_ligne, passive),
% 	    text2(panel_derouler_cycle_t_ligne, select(1))
% 	).
% panel_derouler_cycle_t_changed(panel_derouler_cycle_t, panel_derouler_cycle_rotation, Flag):-
% 	switch(panel_derouler_cycle_t_deroulement_personne, current(on)),
% 	panel_derouler_cycle_init_last_roulement.

% Switch sélection d'un personne
panel_derouler_cycle_t_changed(panel_derouler_cycle_t, panel_derouler_cycle_t_deroulement_personne, Flag):-
	!,
	(Flag = on ->
 	    text2(panel_derouler_cycle_t_personne, open),
 	    text2(panel_derouler_cycle_t_equipe, unmap),
 	    text2(panel_derouler_cycle_t_personne, current(Personne)),
	    panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_personne, Personne),
	    true
	;
 	    text2(panel_derouler_cycle_t_equipe, open),
 	    text2(panel_derouler_cycle_t_personne, unmap),
 	    text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	    panel_derouler_cycle_t_changed(_, panel_derouler_cycle_t_equipe, Equipe),
	    true
	),
	panel_derouler_cycle_init_last_roulement.
	    


% Autre
panel_derouler_cycle_t_changed(_, A, B):-
	writeln('ERROR'-panel_derouler_cycle_t_changed(panel_derouler_cycle_t, A, B)),
	text2(panel_derouler_generateur_cycle_t, select('?')).


	
/*******************************************************************************
* Condition des canevas
*******************************************************************************/
% Module horaire => canevas_t
panel_derouler_cycle_t_canevas_t_condition(panel_derouler_cycle_t_canevas_t, Item):-
	appl_mode_planif(heure),
	!,
	canevas_t(_, get_possible_canevas_t2(Cs)),
	$member(Item, Cs),
	Item@mode_application = '0'.
% Module jour => canevas de l'équipe rédactionnelle
panel_derouler_cycle_t_canevas_t_condition(panel_derouler_cycle_t_canevas_t, Item):-
	not appl_mode_planif(heure),
	!,
	canevas(_, get_possible_canevas2(Cs)),
	$member(Item, Cs),
	Item@mode_application = '0'.


% Module horaire => 
panel_derouler_cycle_t_generateur_condition(panel_derouler_generateur_cycle_t, Item):-
	appl_mode_planif(heure),
	!,
	canevas_t(_, get_possible_canevas_t2(Cs)),
	is_a(Item, generateur_cycle_t),
	$is_member_of(Item@canevas_t, Cs),
	(Item@canevas_t)@mode_application = '0'.
% Module jour => générateurs de l'équipe rédactionnelle
panel_derouler_cycle_t_generateur_condition(panel_derouler_generateur_cycle_t, Item):-
	not appl_mode_planif(heure),
	!,
	canevas(_, get_possible_canevas2(Cs)),
	is_a(Item, generateur_cycle),
	$is_member_of(Item@canevas, Cs),
	(Item@canevas)@mode_application = '0'.


/*******************************************************************************
* Condition des équipes cycliques
*******************************************************************************/
panel_derouler_cycle_t_equipe_condition(_, Item):-
	appl_mode_planif(heure),
	down_role_in_list(planificateur, [gestionnaire_equipe, equipe]),
	!,
	is_a(Item, equipe_cycle_t),
	((mode @ role) @ si_super_role = '1' ->
	    true
	;
	    appl_session_give_loading_object(Item@equipe_redactionnelle)
	).
panel_derouler_cycle_t_equipe_condition(_, Item):-
	appl_mode_planif(heure),
	!,
	is_a(Item, equipe_cycle_t).
panel_derouler_cycle_t_equipe_condition(_, Item):-
	not appl_mode_planif(heure),
	!,
	is_a(Item, equipe_cycle),
	Item@equipe_redactionnelle = jour_parameter@equipe_redactionnelle.


/*******************************************************************************
* Condition sur les personnes
*******************************************************************************/
panel_derouler_cycle_t_personne_condition(_, Item):-
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	instance(Canevas),
	iss_a(Item, personne),
	(instance(Canevas@type_contrat) ->
	    personne(Item, get_contrats(name, X, (X@debut =< To, X@fin >= From, X@type_contrat = Canevas@type_contrat), Contrats)),
	    Contrats \= []
	;
	    true
	).



/*******************************************************************************
* Contrôle de saisie du panel
*******************************************************************************/
panel_derouler_cycle_t_check_panel:-
	warning_destroy,
	fail.
panel_derouler_cycle_t_check_panel:-
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	not instance(Canevas),
	!,
	alert(text@der_selectionner_un_cycle, [text@abort], Answer),
	fail.
% Mode équipe
panel_derouler_cycle_t_check_panel:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	not instance(Equipe),
	!,
	alert(text@der_selectionner_une_equipe, [text@abort], Answer),
	fail.
% Mode personne : Alerte uniquement si pas de type de contrat sur le canevas
panel_derouler_cycle_t_check_panel:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(on)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	not instance(Canevas@type_contrat),
	text2(panel_derouler_cycle_t_personne, current(Personne)),
	not instance(Personne),
	!,
	alert(text@der_selectionner_une_personne, [text@abort], Answer),
	fail.
% Mode personne (Par contrat) : Alerte si plus d'une ligne dans le canevas 
panel_derouler_cycle_t_check_panel:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(on)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	instance(Canevas@type_contrat),
	text2(panel_derouler_cycle_t_personne, current(Personne)),
	not instance(Personne),
	Canevas@nb_lignes > 1,
	!,
	alert(text@der_canevas_too_many_lines, [text@abort], Answer),
	fail.
% Sinon prévient qu'on va dérouler sur toutes les personnes qui ont le bon type de contrat
panel_derouler_cycle_t_check_panel:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(on)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	instance(Canevas@type_contrat),
	text2(panel_derouler_cycle_t_personne, current(Personne)),
	not instance(Personne),

	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),

	all(contrat, personne, [debut =< To, fin >= From, type_contrat = Canevas@type_contrat], [], Personnes),
	util_distinct(Personnes, Personnes_Uniques),
	util_length(Personnes_Uniques, Nb),
	sprintf(Msg, "Attention : Le canevas sera déroulé sur %s personnes", [Nb]),
	alert(Msg, [text@continue, text@cancel], text@cancel),
	!,
	fail.
% Mode équipe
panel_derouler_cycle_t_check_panel:-
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	Canevas@nb_lignes = 0,
	!,
	alert('Action impossible: Le cycle sélectionné ne possède aucune ligne', [text@abort], Answer),
	fail.
% Mode équipe
panel_derouler_cycle_t_check_panel:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_ligne, current(N)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	panel_derouler_equipe_cycle(Equipe, get_nb_personnes(Taille)),
	Taille > 0,
	not ((N >= 1,
	      N =< Taille)),
	specific_parameter(derouler_cycle_check_nb_personnes, Check),
	specific_parameter(derouler_cycle_sur_equipe_invalide, on),
	$member(Check-Label-Buttons, [alert-'Attention'-[text@continue, text@abort], alert2-'Action impossible'-[text@abort]]),
	once((is_a(W, warning),
	      W@message_number = 40004)),
	sprintf(Msg, "Action impossible: La ligne de départ doit être comprise entre 1 et %s", [Taille]),
	alert(Msg, Buttons, text@abort),
	!,
	warning_open_if_exist,
	fail.
% Mode personne
panel_derouler_cycle_t_check_panel:-
%	switch(panel_derouler_cycle_t_deroulement_personne, current(on)),
	text2(panel_derouler_cycle_t_ligne, current(N)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	Taille = Canevas@nb_lignes,
	Taille > 0,
	not ((N >= 1,
	      N =< Taille)),
	!,
	sprintf(Msg, "Action impossible: La ligne de départ doit être comprise entre 1 et %s", [Taille]),
	alert(Msg, [text@abort], Answer),
	fail.
panel_derouler_cycle_t_check_panel:-
	% En planificateur horaire dans un premier temps, il est possible de dérouler le canevas en dehors
	% AJ : le 18/03/2019 : Il semble qu''il y a une petite confusion avec ce paramètre check_canevas_in_period 
	% "in_periode" ==> chargée ou à dérouler 
	% ici le contrôle est sur la validité du canevas par rapport à la période à dérouler et non la période chargée
	% c.f horaire_panel... ou jour_panel... pour la vérification correspondante à la période chargée
% 	(specific_parameter(check_canevas_in_period, on)
%     ;
% 	appl_mode_planif(jour)
%         ),

	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	instance(Canevas),
	not ((Canevas@date_debut =< From,
	      Canevas@date_fin >= To)),
	!,      
	alert('Action impossible: La période de déroulement doit être incluse dans la période de validité du canevas', [text@abort], Answer),
	fail.
% Start doit se trouver dans la période chargée
panel_derouler_cycle_t_check_panel:-
	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_depart_ref, current(From_Ref)),
	Start is min(From, From_Ref),
	Start < mode@start_date,
	!,      
	alert('Action impossible: La période de déroulement se trouve dans le passé. Veuillez modifier celle-ci ou charger la bonne période', [text@abort], Answer),
	fail.
% Controle de la période de reference vs période libre 1
panel_derouler_cycle_t_check_panel:-
	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	From > To,
	!,      
	alert('Action impossible: La période de déroulement est incohérente', [text@abort], Answer),
	fail.
% Controle de la période de reference vs période libre 1
panel_derouler_cycle_t_check_panel:-
	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_depart_ref, current(From_Ref)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	text2(panel_derouler_cycle_t_fin_ref, current(To_Ref)),
	not 
        ((
	    From >= From_Ref,
	    To =< To_Ref
	)),
	!,      
	sprintf(Msg, "Action impossible: La période libre doit être comprise dans la période de référence.\n Veuillez d'abort fixer les périodes de référence en activant l'option '%s' puis fixer la période libre à l'intérieure de la période de référence en désactivant l'option", [text@si_full_amplitude]),
	alert(Msg, [text@abort], Answer),
	fail.
% Controle de la période de reference vs période libre 1
panel_derouler_cycle_t_check_panel:-
	text2(panel_derouler_cycle_t_numero_jour, current(No_Jour)),
	text2(panel_derouler_cycle_t_amplitude, current(Longueur)),
	No_Jour > Longueur,
	!,
	sprintf(Msg, "Action impossible: La valeur du champ '%s' doit être compris entre 1 et %s", [text@no_jour, Longueur]),
	alert(Msg, [text@abort], Answer),
	fail.
	
% panel_derouler_cycle_t_check_panel:-
% 	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
% 	text2(panel_derouler_cycle_t_depart, current(From)),
% 	text2(panel_derouler_cycle_t_fin, current(To)),
% 	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
% 	instance(Canevas),
% 	not ((Equipe@date_debut =< From,
% 	      Equipe@date_fin >= To)),
% 	!,      
% 	alert('Action impossible: La période de déroulement doit être incluse dans la période de validité du canevas', [text@abort], Answer),
% 	fail.	
panel_derouler_cycle_t_check_panel:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),

	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	panel_derouler_equipe_cycle(Equipe, get_personnes(Canevas, Appartenances_Equipes_1)),

	(appl_mode_planif(heure) ->
	    % Technicien
	    [Class_Roulement, Class_Equipe] = [roulement_cycle_t, equipe_cycle_t]
	;
	    % Journaliste
	    [Class_Roulement, Class_Equipe] = [roulement_cycle, equipe_cycle]
	),

	once((
	      $member(ACG_1, Appartenances_Equipes_1),
	      $member(AC_1, ACG_1),
	      AC_1 = t(AC_1_Ressource, AC_1_Debut, AC_1_Fin, _, _),
	      instance(AC_1_Ressource),
	      AC_1_Debut =< To,
	      AC_1_Fin >= From,
	      
	      util_maximum(From_R, [AC_1_Debut, From]),
	      util_minimum(To_R, [AC_1_Fin, To]),
	      
	      is_a(RC, Class_Roulement),
	      RC@ressource = AC_1_Ressource,
	      RC@date_debut =< To_R,
	      RC@date_fin >= From_R
	  )),
	(appl_mode_planif(heure) ->
	    Canevas_Name = (RC@canevas_t)@nom,
	    Personne_Name = (AC_1_Ressource)@label
	;
	    Canevas_Name = (RC@canevas)@nom,
	    Personne_Name = (AC_1_Ressource)@label
	),
	
	% Si on autorise les personnes multi canevas, alors permet de continuer
	(not specific_parameter(allow_multi_cycles_per_personne, on) ->
	    sprintf(Msg, "Action impossible: Des cycles (%s) ont déjà été déroulés sur au moins un des membres de l'équipe (%s) sur la période demandée. Veuillez d'abord, annuler le déroulement de ceux-ci.", [Canevas_Name, Personne_Name]),
	    alert(Msg, [text@abort], Answer)
	;
	    sprintf(Msg, "Attention: Des cycles (%s) ont déjà été déroulés sur au moins un des membres de l'équipe (%s) sur la période demandée. Voulez-vous continuer ?", [Canevas_Name, Personne_Name]),
	    alert(Msg, [text@continue, text@abort], Answer)
	),
	Answer \= text@continue,
	!,	    
	fail.



/*
panel_derouler_cycle_t_check_panel:-
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	equipe_cycle_t(Equipe, get_nb_personnes(N)),
	text2(panel_derouler_cycle_t_occurence, current(Occurence)),
	M is Occurence/N,
	not M*N =:= Occurence,
	!,
	sprintf(Msg, "Action impossible: Le déroulement ne peut se faire que sur %s occurences (pour un cycle complet de l''équipe)", 
                [N]),
	alert(Msg, [text@abort], Answer),
	fail.
*/
panel_derouler_cycle_t_check_panel:-
	not specific_panel_derouler_cycle_check_panel,
	!,
	fail.
panel_derouler_cycle_t_check_panel:-
	warning_destroy,
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	switch(panel_derouler_cycle_rotation, current(Si_Rotation)),

	% Vérifie que des personnes couvrent bien par période désirée
	panel_derouler_equipe_cycle(Equipe, check(valid(Canevas, From, To))),

        % Vérifie que les aptitudes et contrats des personnes couvrent bien par période désirée
	panel_derouler_generator_cycle(_, check(valid(Canevas, Equipe, From, To, Si_Rotation))),

	fail.
% Vérifie que le nombre de personnes est égal au nombre de lignes
% Etape N°1 : Crée des Warning si problèmes d'équipe
panel_derouler_cycle_t_check_panel:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	Canevas@si_cyclique \= '0', % Fonctionne en module horaire qui n'a pas cet attribut pour le moment
	specific_parameter(derouler_cycle_check_nb_personnes, Check),
	specific_parameter(derouler_cycle_sur_equipe_invalide, on),
	$member(Check-Label-Buttons, [alert-'Attention'-[text@continue, text@abort], alert2-'Action impossible'-[text@abort]]),
	once((is_a(W, warning),
	      W@message_number = 40003)),	
	sprintf(Msg, "%s : L'équipe est incomplète sur la période demandée", [Label]),
	alert(Msg, Buttons, text@abort),
	!,
	warning_open_if_exist,
	fail.
% Etape N°2 : Teste si des Warning d'équipe existent
panel_derouler_cycle_t_check_panel:-
	specific_parameter(derouler_cycle_sur_equipe_invalide, on),
	% Il existe au moins un warning distincte de celui d'une personne manquante
	once((is_a(W, warning),
	      W@message_number \= 40003)),
	alert('Attention: L''équipe est incompatible ou invalide sur la période demandée. Voulez-vous continuer?', [text@yes, text@no], Answer),
	Answer = text@no,
	!,
	warning_open_if_exist,
	fail.
panel_derouler_cycle_t_check_panel:-
	not specific_parameter(derouler_cycle_sur_equipe_invalide, on),
	warning_exist,
	alert('Action impossible: L''équipe est incompatible ou invalide sur la période demandée. Vérifiez les avertissements', [text@abort], Answer),
	warning_open_if_exist,
	!,
	fail.
% Mode équipe
panel_derouler_cycle_t_check_panel:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	instance(Equipe),
	%
	(appl_mode_planif(heure) ->
	    % Technicien
	    [Class_Appart_Equipe, Class_Equipe] = [appart_cycle_t, equipe_cycle_t]
	;
	    % Journaliste
	    [Class_Appart_Equipe, Class_Equipe] = [appart_equipe_cycle, equipe_cycle]
	),
	%
	not once((
	iss_a(A, Class_Appart_Equipe),
	A@Class_Equipe == Equipe
        )),
	alert('Attention : l''équipe sélectionnée ne contient personne ', [text@continue, text@abort], Answer),
	Answer \= text@continue,
	!,	    
	fail.

panel_derouler_cycle_t_check_panel.









/*******************************************************************************
*
*
*
*                            Déroulement du cycle
*
*
*
*
*******************************************************************************/
derouler_cycle_t:-	
	busy,
	display_flush,
	fail.
derouler_cycle_t:-
	not derouler_clean_planning_avant_deroulement,
	unbusy,
	!.
derouler_cycle_t:-
	$here system(cls),
	derouler_cycle_t_internal,
	fail.
% Recalcul des compteur
derouler_cycle_t:-
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	switch(panel_derouler_cycle_t_deroulement_personne, current(Si_Personne)),
	(Si_Personne = on ->
	    text2(panel_derouler_cycle_t_personne, current(Personne)),
	    Ps = [Personne]
	;
	    text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	    panel_derouler_equipe_cycle(Equipe, get_personnes(Canevas, Ps0)),
	    panel_deroulement_cycle_get_personne(Ps0, Ps)
	),
	derouler_cycle_after_action(Ps, destroy),
	fail.
derouler_cycle_t:-
	panel_derouler_cycle_t_open_callback,
	fail.
derouler_cycle_t:-
	specific_panel_derouler_after_deroulement,
	change_view(mode@view),
	fail.
derouler_cycle_t:-
	unbusy,
	fail.
derouler_cycle_t:-
	% En module horaire, si on est en mode de création dynamique des taches cycliques,
	% et en mode synchronisé (tâches déroulées en même temps que les vacations)
	% n'ouvre les warnings qu'à la fin de l'upload
	not ((appl_mode_planif(heure),
	      specific_parameter(dynamique_tache_cyclique, on),
	      not specific_parameter(sync_tache_cyclique, off))),
	warning_open_if_exist,
	fail.
derouler_cycle_t:-
	writeln(OK).


/*******************************************************************************
* Code de déroulement
*******************************************************************************/
derouler_cycle_t_internal:-
	busy,
	display_flush,

	% Entend end_date si nécessaire
	panel_derouler_cycle_should_extend_end,

	text2(panel_derouler_cycle_t_depart, current(Min)),
	text2(panel_derouler_cycle_t_fin, current(Max)),
	text2(panel_derouler_cycle_t_depart_ref, current(From)),
	text2(panel_derouler_cycle_t_fin_ref, current(To)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),

	% Activités à dérouler
	panel_derouler_canevas(Canevas, get_activites_lignes(As)),

	text2(panel_derouler_cycle_t_ligne, current(Ligne_Debut0)),
	Ligne_Debut is Ligne_Debut0 - 1,

	% Ressources sur lesquelles dérouler
	switch(panel_derouler_cycle_t_deroulement_personne, current(Si_Personne)),
	switch(panel_derouler_cycle_t_besoin, current(Si_Besoin)),
	text2(panel_derouler_cycle_t_personne, current(Personne)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	panel_derouler_cycle_get_personnes(Si_Personne, Si_Besoin, Personne, Equipe, Canevas, From, To, Ps0),

	(Si_Personne = on ->
	    % Mode personne unique
	    Ps = Ps0
	;
	    % Mode équipe
	    % Applique une rotation sur l''équipe afin de démarrer sur la bonne ligne
	    util_cycle2(Ps0, Ligne_Debut, Ps)
	),

	specific_panel_derouler_before_deroulement,

        % Déconnecte le controle sur la période 
        % -> Permet de faire des déroulements sur des périodes dépassant la macro-période (i.e. l'horizon de chargement)
	jour_parameter@check_obj_in_periode <<- no,

	derouler_cycle_t(As, Ps, From, To, Min, Max, Canevas, Canevas@longueur, Ligne_Debut),
	fail.
derouler_cycle_t_internal.



/*******************************************************************************
* Nettoie un planning avant déroulement
*******************************************************************************/
derouler_clean_planning_avant_deroulement:-
	% Si une personne peut appartenir à plusieurs cycles déroulés, 
	% alors le nettoyage de planning avant déroulement n''est plus possible
	specific_parameter(allow_multi_cycles_per_personne, on),
	!.
derouler_clean_planning_avant_deroulement:-
	not specific_parameter(derouler_cycle_proposer_destruction_planning_cyclique, off), % Si on doit proposer de supprimer le plannig cyclique avant de dérouler le cycle
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	panel_derouler_equipe_cycle(Equipe, get_personnes(Canevas, Ps)),
	% On vérifie si des activites ou des indispos cycliques sont présentes dans le planning
	once((
	      specific_panel_derouler_cycle_check_presence_activites_cycliques(Ps, From, To, Canevas)
	  ; 
	      specific_panel_derouler_cycle_check_presence_indispos_cycliques(Ps, From, To, Canevas)
	)),
	% On affiche une alerte
	mu_date_make_atom(From, date3, AtomF),
	mu_date_make_atom(To, date3, AtomT),
	sprintf(Msg, "Attention: Cette action va re-initialiser les plannings des ressources de l''équipe du %s au %s. Voulez-vous continuer?", [AtomF, AtomT]),
	alert(Msg, [text@yes, text@no], Answer),
	Answer = text@no,
	!,
	fail.
derouler_clean_planning_avant_deroulement:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),	
	panel_derouler_equipe_cycle(Equipe, get_personnes(Canevas, Ps)),
	% DETRUIT LE PLANNING CYCLIQUE
	specific_panel_derouler_cycle_clean_activites_cycliques(Ps, From, To, Canevas),
	specific_panel_derouler_cycle_clean_indispos_cycliques(Ps, From, To, Canevas),
	fail.
derouler_clean_planning_avant_deroulement:-
	switch(panel_derouler_cycle_t_deroulement_personne, current(off)),
	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	text2(panel_derouler_cycle_t_equipe, current(Equipe)),

	panel_derouler_equipe_cycle(Equipe, get_personnes(Canevas, Ps)),

	(specific_parameter(derouler_cycle_proposer_destruction_indispos, off) ->
	    Answer = text@no
	;
	    % Vérifier si il y a au moins une pour afficher l'alerte
	    (specific_panel_derouler_cycle_check_presence_indispos_non_cycliques(Ps, From, To, Canevas) ->
		alert('Désirez-vous détruire les indisponibilités', [ text@no, text@yes], Answer)
	    ;
		Answer = text@no
	    )
	),
	% DETRUIT LES INDISPOS NON CYCLIQUE SI Answer = text@yes
	specific_panel_derouler_cycle_clean_indispos_non_cycliques(Ps, From, To, Canevas, Answer),
	%
	%
	(specific_parameter(derouler_cycle_proposer_destruction_activites, off) ->
	    Answer2 = text@no
	;
	    % Vérifier si il y a au moins une pour afficher l'alerte
	    (specific_panel_derouler_cycle_check_presence_activites_non_cycliques(Ps, From, To, Canevas) ->
		alert('Désirez-vous détruire les activites', [ text@no, text@yes], Answer2)
	    ;
		Answer2 = text@no
	    )
	),
	% DETRUIT LES ACTIVITES NON CYCLIQUES SI Answer = text@yes
	specific_panel_derouler_cycle_clean_activites_non_cycliques(Ps, From, To, Canevas, Answer2),
	fail.
derouler_clean_planning_avant_deroulement.












/*******************************************************************************
* Déroules les activités sur une liste de personnes
*******************************************************************************/
derouler_cycle_t(As, Ps, From, To, Min, Max, Canevas, Amplitude, Occurence):-
	From >= To,
	!.
% En mode hoaire, demande un id de constrainte horaire pour chaque tache
derouler_cycle_t(As, Ps, From, To, Min, Max, Canevas, Amplitude, Occurence):-
	appl_mode_planif(heure),
	mu_append_lp(As, All),
	vue_annuelle_canevas_init_cst(All),
	fail.
derouler_cycle_t(As, Ps, From, To, Min, Max, Canevas, Amplitude, Occurence):-	
	Next is From+Amplitude*1440,
	mu_date_make_atom(From, date3, AtomF),
	mu_date_make_atom(Next, date3, AtomN),
	switch(panel_derouler_cycle_rotation, current(Si_rotation)),
	switch(panel_derouler_cycle_t_si_remplacement, current(Si_Remplacement)),
	switch(panel_derouler_cycle_t_si_sans_chgt_planning, current(Si_Sans_Chgt_Planning0)),
	$member(Si_Sans_Chgt_Planning0-Si_Sans_Chgt_Planning, ['on'-'1', 'off'-'0']),

	% writeln('-----------------------------------------'-From-Next),	
	% nl, writeln('Nouvelle Occurence'-AtomF-AtomN),
	% mu_date(From),
	% mu_date(Next),

	To2 is Next-1440,
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	switch(panel_derouler_cycle_t_deroulement_personne, current(Si_Personne)),
	(Si_Personne = on ->
	    Equipe = -,
	    true
	;
	    text2(panel_derouler_cycle_t_equipe, current(Equipe))
	),

	(appl_mode_planif(heure) ->
	    [Class_Canevas, Class_Equipe_Cycle] = [canevas_t, equipe_cycle_t],
	    Parameters = []
	;
	    [Class_Canevas, Class_Equipe_Cycle] = [canevas, equipe_cycle],
	    etat(jour_parameter@etat_par_defaut, find_etat(Etat, on)),
	    Parameters = [Etat]),

	$member(Si_rotation-Si_rotation_Value, ['on'-'1', 'off'-'0']),
	
	% Donne un nouvel ID de roulement
	derouler_cycle_get_next_id(Id),

	% Deconnect l'attribution de contrainte horaire pendant la création de tache cyclique
	mode@user_action <<- no_new_cst_planning_t_h,
	NOccurence is Occurence + 1,
	% On ne désynchronise le roulement que pour le module horaire pour le moment
	((specific_parameter(sync_tache_cyclique, off), appl_mode_planif(heure)) ->
	    Si_Taches_Deroulees = '0'
	;
	    Si_Taches_Deroulees = '1'
	),
	Rotation_Atts = [Class_Canevas <- Canevas, Class_Equipe_Cycle <- Equipe, numero_ligne_init <- NOccurence,
	                 si_rotation <- Si_rotation_Value, date_debut_roulement <- From, date_fin_roulement <- To2, 
			 si_taches_deroulees <- Si_Taches_Deroulees],
%	nl,		 
%	writeln(derouler_cycle_t_build_one_occurence(As, Ps, From, Min, Max, Canevas, Amplitude, Id, Parameters, Rotation_Atts, Si_Remplacement, Si_Sans_Chgt_Planning)),		 
	derouler_cycle_t_build_one_occurence(As, Ps, From, Min, Max, Canevas, Amplitude, Id, Parameters, Rotation_Atts, Si_Remplacement, Si_Sans_Chgt_Planning),
	derouler_cycle_t_after_build_one_occurence(As, Ps, From, Min, Max, Canevas, Amplitude, Id, Parameters, Rotation_Atts, Si_Remplacement),
	% fait tourner les personnes
	(Si_rotation = on ->
	    Next_Occurence is mod(Occurence + 1, Canevas@nb_lignes),
	    util_cycle2(Ps, 1, NPs)
	;
	    Next_Occurence is Occurence,
	    NPs = Ps
	),
	!,
	derouler_cycle_t(As, NPs, Next, To, Min, Max, Canevas, Amplitude, Next_Occurence).


/*******************************************************************************
*
*******************************************************************************/
derouler_cycle_t_after_build_one_occurence(As, Ps, From, Min, Max, Canevas, Amplitude, Id, Parameters, Rotation_Atts, Si_Remplacement):-
	specific_derouler_cycle_t_after_build_one_occurence(As, Ps, From, Min, Max, Canevas, Amplitude, Id, Parameters, Rotation_Atts, Si_Remplacement),
	!.
derouler_cycle_t_after_build_one_occurence(As, Ps, From, Min, Max, Canevas, Amplitude, Id, Parameters, Rotation_Atts, Si_Remplacement).


/*******************************************************************************
* Construit une occurence
*******************************************************************************/
derouler_cycle_t_build_one_occurence([], [], From, Min, Max, Canevas, Amplitude, Id, Parameters, Rotation_Atts, Si_Remplacement, Si_Sans_Chgt_Planning).
derouler_cycle_t_build_one_occurence([A|As], [AEP|AEPs], From, Min, Max, Canevas, Amplitude, Id, Parameters, Rotation_Atts, Si_Remplacement, Si_Sans_Chgt_Planning):-
	To is From+Amplitude*1440 - 1440,
%	writeln('-----------------------------------------'),
	derouler_cycle_t_build_one_personne_week(A, From, To, Min, Max, AEP, Canevas, Id, Parameters, Rotation_Atts, Si_Remplacement, Si_Sans_Chgt_Planning),
	!,
	derouler_cycle_t_build_one_occurence(As, AEPs, From, Min, Max, Canevas, Amplitude, Id, Parameters, Rotation_Atts, Si_Remplacement, Si_Sans_Chgt_Planning).

	


/*******************************************************************************
* Affecte les activités à une personne
*******************************************************************************/
derouler_cycle_t_build_one_personne_week(AC_J, From0, To0, Min, Max, AE_L, Canevas, Id, Parameters, Rotation_Atts, Si_Remplacement, Si_Sans_Chgt_Planning):-
	% nl, writeln(start-derouler_cycle_t_build_one_personne_week),
	% writeln(initiale),
	% mu_date(From0),
	% mu_date(To0),

	% Prend en compte la période libre
	From is max(From0, Min),
        To is min(To0, Max),

	% nl, writeln(corrigée),
	% mu_date(From),
	% mu_date(To),

	% Prend l'appartenance equipe personne associé à cette date
	$member(AEP, AE_L),
	AEP = t(Personne, AEP_From, AEP_To, AEP_Numero, AEP_Principal),

	% Ressource valide sur au moins une partie du déroulement
	mu_overlapp(From, To, AEP_From, AEP_To, R_From, R_To),
	% Prend en compte la période libre
	R_From2 is max(R_From, Min),
        R_To2 is min(R_To, Max),

	% nl, writeln(rouilement),
	% mu_date(R_From2),
	% mu_date(R_To2),
	% nl,

	% Vérifie qu'aucun roulement n'existe sur cette période
	(appl_mode_planif(heure) ->
	    not roulement_cycle_t(_, get_roulement_personne(Canevas, Personne, From, To))
	;
	    not roulement_cycle(_, get_roulement_personne(Canevas, Personne, From, To))
	),

	AC_J = [FAC|_],
	(appl_mode_planif(heure) ->
	    Numero_Ligne = (FAC@ligne_canevas_t)@numero
	;
	    Numero_Ligne = (FAC@ligne_canevas)@numero
	),
	writeln(Numero_Ligne-Personne@label),


	% Création d'un roulement sur la personne
 	panel_derouler_roulement_cycle(Roul, new_light([ressource <- Personne, date_debut <- R_From2, date_fin <- R_To2, id_roulement <- Id, numero_ligne <- Numero_Ligne, numero_ligne_tmp <- Numero_Ligne, si_sans_chgt_planning <- Si_Sans_Chgt_Planning|Rotation_Atts])),

	% S'arrete ici si l'on ne doit pas toucher au planning	
	Si_Sans_Chgt_Planning = '0',
	

	% ????
	derouler_cycle_update_indispos(Personne, R_From2, R_To2),


	% Pour chaque debut de journée, reinitialise le tag des erreurs des vacations
	setval($deroulement_cycle_vacation_t_error, 0),

	% Prend une activite d'une ligne
	$member(AC, AC_J),

	% Si la vacation n'a pas été créé, alors ne créé aucune tache cyclique
	(getval($deroulement_cycle_vacation_t_error, 1) ->
	    $rem writeln(ERREUR-CREATION_VACATION),
	    $here AC@class \= tache_canevas_t
	;
	    true
	),

	Start is From0 + (AC@numero_jour-1)*1440 + AC@heure_debut,

	% writeln(AC),
	% write('From0 '), mu_date(From0),
	% writeln('AC@numero_jour'-AC@numero_jour),
	% write('Start'), mu_date(Start),

	% Vérifie qu'appartient à la periode libre
	(Start/1440) >= (Min/1440),
	(Start/1440) =< (Max/1440),

	End is From0 + (AC@numero_jour-1)*1440 + AC@heure_fin,

	% Ressource valide sur l'activité
	AEP_From/1440 =< Start/1440,
	AEP_To/1440 >= Start/1440,
	setval($crt_cyc, 1),
	specific_panel_derouler_cycle_build_one_personne_week(AC@class, AC, AEP, From0, Start, End, Id, Parameters, Si_Remplacement),
	setval($crt_cyc, 0),
	fail.
derouler_cycle_t_build_one_personne_week(_, From, To, Min, Max, _, Canevas, Id, _, _, Si_Remplacement, Si_Sans_Chgt_Planning).




/*******************************************************************************
* A partir d''une liste de listes d''appartenance cycle, extrait les personnes
*******************************************************************************/
panel_deroulement_cycle_get_personne([], []).
panel_deroulement_cycle_get_personne([L|Ls], Ps):-
	panel_deroulement_cycle_get_personne_lp2(L, Ps, NQs),
	panel_deroulement_cycle_get_personne(Ls, NQs).


panel_deroulement_cycle_get_personne_lp2([], Qs, Qs).
panel_deroulement_cycle_get_personne_lp2([AEP|AEPs], [Personne|Qs], NQs):-
	AEP = t(Personne, From, To, Numero, Principal),
	instance(Personne),
	!,
	panel_deroulement_cycle_get_personne_lp2(AEPs, Qs, NQs).
panel_deroulement_cycle_get_personne_lp2([_|AEPs], Qs, NQs):-
	panel_deroulement_cycle_get_personne_lp2(AEPs, Qs, NQs).




/*******************************************************************************
* Relance le calcul des compteurs
*******************************************************************************/
derouler_cycle_after_action(Ps, Action):-
	writeln(derouler_cycle_after_action(Ps, Action)),
	down_role(planificateur, Type),
	$member(Type, [micro_planificateur, gestionnaire_micro]),
	decompte_personne(_, create_and_compute(Ps, jour_parameter@jour_j)),
	fail.
derouler_cycle_after_action(Ps, Action):-
	% mise à jour des lignes de personne du panel compteur d''équité
	panel_compteur_equite_update_personnes(Ps, _, _),
	fail.
derouler_cycle_after_action(Ps, Action):-
	specific_derouler_cycle_after_action(Ps, Action),
	fail.
derouler_cycle_after_action(Ps, Action).






/*******************************************************************************
* Récupère l''id de déroulement courant
*******************************************************************************/
% Si connecté a la base, on passe par la séquence
derouler_cycle_get_next_id(Id):-
	db_connected,
	!,
	mu_db_tuple("SELECT OPTI_SEQ_ID_ROULEMENT.NEXTVAL FROM DUAL", [], Tuple),
	Tuple = tuple(Id).

% Sinon on passe par un compteur
% Module horaire
derouler_cycle_get_next_id(Id):-
	appl_mode_planif(heure),
	getval($canevas_id_roulement, 0),
	!,
	all(tache_cyclique, id_roulement, [], [], Ids0),
	all(vacation_t, id_roulement, [], Ids0, Ids1),
	all(indispo_planif, id_roulement, [], Ids1, Ids),
	util_maximum(Id0, Ids),
	Id is Id0 + 1,
	setval($canevas_id_roulement, Id).

% Module jour
derouler_cycle_get_next_id(Id):-
	not appl_mode_planif(heure),
	% Variable non créée, on la positionne au max des id_roulement actuels + 1
	getval($canevas_id_roulement, 0),
	!,
	all(etiquette, id_roulement, [], [], Ids0),
	all(indispo_planif, id_roulement, [], Ids0, Ids),
	util_maximum(Id0, Ids),
	Id is Id0 + 1,
	setval($canevas_id_roulement, Id).

% Le compteur existe
derouler_cycle_get_next_id(Id):-
	incval($canevas_id_roulement, Id).




/*******************************************************************************
* Liste des personnes de l''équipe
*******************************************************************************/
% Mode Equipe
panel_derouler_cycle_get_personnes(off, Si_Besoin, _, Equipe, Canevas, From, To, Ps):-
	!,
	% Personnes de l'équipe
	panel_derouler_equipe_cycle(Equipe, get_personnes(Canevas, Ps0)),
	
	% Si on génère des besoins, complète l'équipe avec des lignes anonymes ('-')
	(Si_Besoin = on ->
	    panel_derouler_canevas(Canevas, get_lines(LCs)),
	    panel_derouler_equipe_cycle_add_besoins(1, LCs, Ps0, From, To, Ps)
	;
	    Ps = Ps0
	).
% Mode Personnes : On construit une équipe "virtuelle"
panel_derouler_cycle_get_personnes(on, Si_Besoin, Personne, _, Canevas, From, To, Ps):-
	Nb_Personnes = Canevas@nb_lignes,
	instance(Personne),
	!,
	text2(panel_derouler_cycle_t_ligne, current(Ligne_Debut)),

	panel_derouler_cycle_get_personnes_lp(Personne, Ligne_Debut, 1, Nb_Personnes, Ps).

% Mode Personnes (Contrat): On construit une équipe "virtuelle"
% ATTENTION : Point de choix pour faire N fois le déroulement par personne
panel_derouler_cycle_get_personnes(on, Si_Besoin, Personne0, _, Canevas, From, To, Ps):-
	not instance(Personne0),
	instance(Canevas@type_contrat),

	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),

	all(contrat, personne, [debut =< To, fin >= From, type_contrat = Canevas@type_contrat], [], Personnes),

	text2(panel_derouler_cycle_t_ligne, current(Ligne_Debut)),
	Nb_Personnes = Canevas@nb_lignes,

	$member(Personne, Personnes),
	% N'est pas déjà déroulée à cette date
	panel_derouler_cycle_get_personnes_lp(Personne, Ligne_Debut, 1, Nb_Personnes, Ps).



/*******************************************************************************
* Equipe virtuelle contenant uniquement la personne
*******************************************************************************/
panel_derouler_cycle_get_personnes_lp(Personne, Ligne_Debut, Current, Nb_Personnes, []):-
	Current > Nb_Personnes,
	!.
panel_derouler_cycle_get_personnes_lp(Personne, Ligne_Debut, Current, Nb_Personnes, [[t(Personne, 0, 99999999, Ligne_Debut, '1')]|Ps]):-
	Ligne_Debut = Current,
	!,
	Current1 is Current + 1,
	panel_derouler_cycle_get_personnes_lp(Personne, Ligne_Debut, Current1, Nb_Personnes, Ps).
panel_derouler_cycle_get_personnes_lp(Personne, Ligne_Debut, Current, Nb_Personnes, [[]|Ps]):-
	!,
	Current1 is Current + 1,
	panel_derouler_cycle_get_personnes_lp(Personne, Ligne_Debut, Current1, Nb_Personnes, Ps).



/*******************************************************************************
* Complète la liste des équipes pour la génération de tâches non affectées
*******************************************************************************/
panel_derouler_equipe_cycle_add_besoins(Numero, [], [], From, To, []).
panel_derouler_equipe_cycle_add_besoins(Numero, [LC|LCs], [Ps_In|PsL_In], From, To, [Ps_Out|PsL_Out]):-
	panel_derouler_equipe_cycle_add_besoins_lp(Numero, Ps_In, From, To, Ps_Out),
	Numero1 is Numero + 1,
	panel_derouler_equipe_cycle_add_besoins(Numero1, LCs, PsL_In, From, To, PsL_Out).
	

% Liste vide, Tout a été couvert
panel_derouler_equipe_cycle_add_besoins_lp(Numero, [], From, To, []):-
	From > To,
	!.
% Liste vide, une partie n'est pas couverte
panel_derouler_equipe_cycle_add_besoins_lp(Numero, [], From, To, [t('-', From, To, Numero, '1')]):-
	!.
% Le début de l'appartenance est avant le début du roulement
panel_derouler_equipe_cycle_add_besoins_lp(Numero, [AEP|AEPs], From, To, [AEP|AEPs_Out]):-
	AEP = t(Personne, AEP_From, AEP_To, AEP_Numero, AEP_Principal),
	AEP_From =< From,
	!,
	AEP_To1 is AEP_To + 1440,
	panel_derouler_equipe_cycle_add_besoins_lp(Numero, AEPs, AEP_To1, To, AEPs_Out).
% Le début de l'appartenance est après le début du roulement
panel_derouler_equipe_cycle_add_besoins_lp(Numero, [AEP|AEPs], From, To, [AEP_N, AEP|AEPs_Out]):-
	AEP = t(Personne, AEP_From, AEP_To, AEP_Numero, AEP_Principal),
	AEP_From > From,
	!,
	AEP_From1 is AEP_From - 1440,
	AEP_N = t('-', From, AEP_From1, Numero, '1'),
	AEP_To1 is AEP_To + 1440,
	panel_derouler_equipe_cycle_add_besoins_lp(Numero, AEPs, AEP_To, To, AEPs_Out).
	






/*******************************************************************************
*
*
*
*                CHARGE LE PLANNING COMPLEMENTAIRE
*
*
*
*
*******************************************************************************/
/*
panel_derouler_cycle_download_extra_planning:-
	!.
*/


/*******************************************************************************
* Chargement du planning complémentaire afin de pouvoir faire les tests de non
* chevauchement
*******************************************************************************/
panel_derouler_cycle_download_extra_planning:-
	% N'est utile que si le déroulement en dehors du planning est possible
	specific_parameter(check_canevas_in_period, on),
	!.
panel_derouler_cycle_download_extra_planning:-
	% N'est utile que si le déroulement est en dehors du planning
	text2(panel_derouler_cycle_t_fin, current(To)),
	not (To >= mode@end_date),
	!.
panel_derouler_cycle_download_extra_planning:-
	% Entend end_date si nécessaire
	panel_derouler_cycle_should_extend_end,

	busy,
	% Récupere les personnes concernées et recharge le planning manquant
	text2(panel_derouler_cycle_t_canevas_t, current(Canevas)),
	switch(panel_derouler_cycle_t_deroulement_personne, current(Si_Personne)),
	(Si_Personne = on ->
	    text2(panel_derouler_cycle_t_personne, current(Personne)),
	    Ps = [Personne]
	;
	    text2(panel_derouler_cycle_t_equipe, current(Equipe)),
	    panel_derouler_equipe_cycle(Equipe, get_personnes(Canevas, Ps0)),
	    panel_deroulement_cycle_get_personne(Ps0, Ps)
	),
%	writeln(Ps),
	panel_derouler_cycle_reload(Ps),
	fail.
panel_derouler_cycle_download_extra_planning:-
	!,
	unbusy.


/*******************************************************************************
* Recharge la partie manquante du planning sur les périodes de l''équipe
*******************************************************************************/
panel_derouler_cycle_reload(Ps):-
	text2(panel_derouler_cycle_t_depart, current(From)),
	text2(panel_derouler_cycle_t_fin, current(To)),
	
	% Refresh sans toucher aux attributs modifiés
	refresh_set_mode(keep_change),
	% mode@download_mode <<- refresh,


	% Si la gestion dynamique des taches cycliques est activée, alors
	% ne charge pas les taches cycliques complémentaires
	(specific_parameter(dynamique_tache_cyclique, on) ->
	    mode@refresh_ignore_class <<- [tache_cyclique]
	;
	    true
	),

	% Je ne charge que le complémentaire
	From2 is max(From, mode@start_date),
%	$rem writeln('Chargement en cascade'-Ps-de(From)-a(To)),
	From2 =< To,

	% Je MAJ les attributs start_date & end_date servant au download
	mode@start_date <<- From2,
	mu_date(mode@start_date),
	mu_date(mode@end_date),
	%
	% Pour que la construction des conditions de chargement ne se base pas sur la macro_periode mais sur [mode@start_date - mode@end_date]
	jour_parameter @ macro_periode <<- 0,

	member(P, Ps),
%	writeln(reload-P-From2-To2),

	% Recharge en cascade des objets liées à Instance
	refresh_reload_cascade(P@class, P),

	fail.
panel_derouler_cycle_reload(Ps).



/*******************************************************************************
*
*******************************************************************************/
derouler_cycle_update_indispos(Personne, From, To):-
	personne(Personne, get_planning(From, To, [class = indispo_planif], Indispos)),
	$member(I, Indispos),
	indispo_planif(I, set_duree([])),
	fail.
derouler_cycle_update_indispos(Personne, From, To).



% End Of File %
 